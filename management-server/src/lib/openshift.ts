import type { StudentEnvironment, ClusterHealth } from "./types";

// OpenShift/Kubernetes client wrapper
// Uses @kubernetes/client-node when running in-cluster or with kubeconfig.
// Falls back to stub data in development.

let k8sAvailable = false;
let coreApi: unknown = null;
let appsApi: unknown = null;

async function initClient() {
  try {
    const k8s = await import("@kubernetes/client-node");
    const kc = new k8s.KubeConfig();
    kc.loadFromDefault();
    coreApi = kc.makeApiClient(k8s.CoreV1Api);
    appsApi = kc.makeApiClient(k8s.AppsV1Api);
    k8sAvailable = true;
  } catch {
    console.warn(
      "Kubernetes client not available — using stub data. " +
        "Set KUBECONFIG or run in-cluster for real data."
    );
    k8sAvailable = false;
  }
}

// Initialize on first import
const clientReady = initClient();

export async function listStudents(): Promise<StudentEnvironment[]> {
  await clientReady;

  if (!k8sAvailable || !coreApi) {
    return getStubStudents();
  }

  try {
    const core = coreApi as {
      listNamespace(
        ...args: unknown[]
      ): Promise<{ body: { items: Array<{ metadata: { name: string; labels?: Record<string, string>; creationTimestamp?: string } }> } }>;
      listNamespacedPod(
        namespace: string,
        ...args: unknown[]
      ): Promise<{ body: { items: Array<{ metadata: { name: string }; status: { phase: string } }> } }>;
    };

    const nsResponse = await core.listNamespace(
      undefined,
      undefined,
      undefined,
      undefined,
      "student"
    );

    const students: StudentEnvironment[] = [];

    for (const ns of nsResponse.body.items) {
      const name = ns.metadata.name;
      const profile = ns.metadata.labels?.["profile"] || "unknown";

      let status: StudentEnvironment["status"] = "unknown";
      let podName: string | undefined;
      let podPhase: string | undefined;

      try {
        const podResponse = await core.listNamespacedPod(
          name,
          undefined,
          undefined,
          undefined,
          undefined,
          "app=code-server"
        );

        if (podResponse.body.items.length > 0) {
          const pod = podResponse.body.items[0];
          podName = pod.metadata.name;
          podPhase = pod.status.phase;
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

      students.push({
        name,
        namespace: name,
        profile,
        status,
        podName,
        podPhase,
        createdAt: ns.metadata.creationTimestamp,
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

// Stub data for development without cluster access
function getStubStudents(): StudentEnvironment[] {
  return [
    {
      name: "student01",
      namespace: "student01",
      profile: "devops-bootcamp",
      status: "running",
      podName: "code-server-abc123",
      podPhase: "Running",
      createdAt: new Date().toISOString(),
    },
    {
      name: "student02",
      namespace: "student02",
      profile: "devops-bootcamp",
      status: "running",
      podName: "code-server-def456",
      podPhase: "Running",
      createdAt: new Date().toISOString(),
    },
    {
      name: "student03",
      namespace: "student03",
      profile: "java-dev",
      status: "pending",
      podName: "code-server-ghi789",
      podPhase: "Pending",
      createdAt: new Date().toISOString(),
    },
  ];
}
