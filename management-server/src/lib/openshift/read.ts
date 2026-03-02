import type {
  StudentEnvironment,
  ClusterHealth,
} from "../types";
import { clientReady, getClientState } from "./client";
import { getStubStudents } from "./stubs";

export async function listStudents(): Promise<StudentEnvironment[]> {
  await clientReady;

  const { k8sAvailable, coreApi, customApi } = getClientState();
  if (!k8sAvailable || !coreApi) {
    return getStubStudents();
  }

  try {
    const nsResponse = await coreApi.listNamespace({
      labelSelector: "app=student-env",
    });

    const students: StudentEnvironment[] = [];

    for (const ns of nsResponse.items) {
      const name = ns.metadata?.name || "";
      const profile = ns.metadata?.labels?.["profile"] || "unknown";

      let status: StudentEnvironment["status"] = "unknown";
      let podName: string | undefined;
      let podPhase: string | undefined;
      let routeUrl: string | undefined;

      try {
        const podResponse = await coreApi.listNamespacedPod({
          namespace: name,
          labelSelector: "app=code-server",
        });

        if (podResponse.items.length > 0) {
          const pod = podResponse.items[0];
          podName = pod.metadata?.name;
          podPhase = pod.status?.phase;
          status =
            podPhase === "Running"
              ? "running"
              : podPhase === "Pending"
                ? "pending"
                : "failed";
        }
      } catch {
        status = "unknown";
      }

      if (customApi) {
        try {
          const routes = await customApi.listNamespacedCustomObject({
            group: "route.openshift.io",
            version: "v1",
            namespace: name,
            plural: "routes",
            labelSelector: "app=code-server",
          });
          if (routes.items?.length > 0) {
            const host = routes.items[0].spec?.host;
            if (host) {
              routeUrl = `https://${host}`;
            }
          }
        } catch {
          // Routes API not available (plain k8s cluster)
        }
      }

      students.push({
        name,
        namespace: name,
        profile,
        status,
        podName,
        podPhase,
        routeUrl,
        createdAt: ns.metadata?.creationTimestamp?.toISOString(),
      });
    }

    return students;
  } catch (error) {
    console.error("Failed to list students:", error);
    return [];
  }
}

export async function getStudentStatus(
  namespace: string
): Promise<StudentEnvironment | null> {
  const students = await listStudents();
  return students.find((s) => s.namespace === namespace) || null;
}

export async function getClusterHealth(): Promise<ClusterHealth> {
  await clientReady;

  const { k8sAvailable } = getClientState();
  if (!k8sAvailable) {
    return {
      connected: false,
      studentCount: 0,
      runningPods: 0,
      failedPods: 0,
      profiles: {},
    };
  }

  const students = await listStudents();
  const profiles: Record<string, number> = {};

  for (const s of students) {
    profiles[s.profile] = (profiles[s.profile] || 0) + 1;
  }

  return {
    connected: true,
    studentCount: students.length,
    runningPods: students.filter((s) => s.status === "running").length,
    failedPods: students.filter((s) => s.status === "failed").length,
    profiles,
  };
}
