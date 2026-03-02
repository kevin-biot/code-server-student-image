import type {
  StudentEnvironment,
  ClusterHealth,
  ProfileSpec,
} from "./types";

// OpenShift/Kubernetes client wrapper
// Uses @kubernetes/client-node v1.4.0+ (object-style params, no .body wrapper).
// Falls back to stub data in development.

// ── K8s response types ──────────────────────────────────────────────

interface K8sMeta {
  name?: string;
  namespace?: string;
  labels?: Record<string, string>;
  creationTimestamp?: Date;
}

interface K8sNamespace {
  metadata?: K8sMeta;
}

interface K8sPod {
  metadata?: K8sMeta;
  status?: { phase?: string };
}

interface K8sRoute {
  metadata?: K8sMeta;
  spec?: { host?: string };
}

// ── Typed API interfaces (v1.4.0 object-param style) ────────────────

interface CoreV1Api {
  listNamespace(opts?: {
    labelSelector?: string;
  }): Promise<{ items: K8sNamespace[] }>;

  createNamespace(opts: { body: unknown }): Promise<K8sNamespace>;
  deleteNamespace(opts: { name: string }): Promise<unknown>;

  listNamespacedPod(opts: {
    namespace: string;
    labelSelector?: string;
  }): Promise<{ items: K8sPod[] }>;

  deleteNamespacedPod(opts: {
    name: string;
    namespace: string;
  }): Promise<unknown>;

  createNamespacedServiceAccount(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;

  createNamespacedResourceQuota(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;

  createNamespacedLimitRange(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;

  createNamespacedPersistentVolumeClaim(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;

  createNamespacedService(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;
}

interface AppsV1Api {
  createNamespacedDeployment(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;
}

interface NetworkingV1Api {
  createNamespacedNetworkPolicy(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;
}

interface RbacV1Api {
  createNamespacedRoleBinding(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;
}

interface CustomObjectsApi {
  createNamespacedCustomObject(opts: {
    group: string;
    version: string;
    namespace: string;
    plural: string;
    body: unknown;
  }): Promise<unknown>;

  listNamespacedCustomObject(opts: {
    group: string;
    version: string;
    namespace: string;
    plural: string;
    labelSelector?: string;
  }): Promise<{ items: K8sRoute[] }>;
}

// ── Client setup ────────────────────────────────────────────────────

let k8sAvailable = false;
let coreApi: CoreV1Api | null = null;
let appsApi: AppsV1Api | null = null;
let networkingApi: NetworkingV1Api | null = null;
let rbacApi: RbacV1Api | null = null;
let customApi: CustomObjectsApi | null = null;

async function initClient() {
  try {
    const k8s = await import("@kubernetes/client-node");
    const kc = new k8s.KubeConfig();
    kc.loadFromDefault();
    coreApi = kc.makeApiClient(k8s.CoreV1Api) as unknown as CoreV1Api;
    appsApi = kc.makeApiClient(k8s.AppsV1Api) as unknown as AppsV1Api;
    networkingApi = kc.makeApiClient(
      k8s.NetworkingV1Api
    ) as unknown as NetworkingV1Api;
    rbacApi = kc.makeApiClient(
      k8s.RbacAuthorizationV1Api
    ) as unknown as RbacV1Api;
    customApi = kc.makeApiClient(
      k8s.CustomObjectsApi
    ) as unknown as CustomObjectsApi;
    k8sAvailable = true;
  } catch {
    console.warn(
      "Kubernetes client not available — using stub data. " +
        "Set KUBECONFIG or run in-cluster for real data."
    );
    k8sAvailable = false;
  }
}

const clientReady = initClient();

// ── Read operations ─────────────────────────────────────────────────

export async function listStudents(): Promise<StudentEnvironment[]> {
  await clientReady;

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

      // Get route URL (OpenShift only)
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
            if (host) routeUrl = `https://${host}`;
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

// ── Create operations ───────────────────────────────────────────────

export interface CreateStudentOpts {
  name: string;
  profile: string;
  clusterDomain: string;
  password: string;
  image?: string;
  spec: ProfileSpec;
}

export interface CreateResult {
  success: boolean;
  namespace: string;
  routeUrl?: string;
  error?: string;
}

export async function createStudentEnvironment(
  opts: CreateStudentOpts
): Promise<CreateResult> {
  await clientReady;

  if (!k8sAvailable || !coreApi || !appsApi || !rbacApi || !networkingApi) {
    return {
      success: false,
      namespace: opts.name,
      error: "Cluster not connected",
    };
  }

  const ns = opts.name;
  const labels = {
    app: "student-env",
    student: ns,
    profile: opts.profile,
    workshop: "training",
    environment: "training",
  };
  const image =
    opts.image ||
    process.env.CODE_SERVER_IMAGE ||
    "training-platform-base:v1.0.0";

  try {
    // 1. Namespace
    await coreApi.createNamespace({
      body: {
        apiVersion: "v1",
        kind: "Namespace",
        metadata: { name: ns, labels },
      },
    });

    // 2. ServiceAccount (pipeline — for Tekton)
    await coreApi.createNamespacedServiceAccount({
      namespace: ns,
      body: {
        apiVersion: "v1",
        kind: "ServiceAccount",
        metadata: {
          name: "pipeline",
          labels: { ...labels, app: "tekton" },
        },
      },
    });

    // 3. RoleBinding — student admin access
    await rbacApi.createNamespacedRoleBinding({
      namespace: ns,
      body: {
        apiVersion: "rbac.authorization.k8s.io/v1",
        kind: "RoleBinding",
        metadata: { name: "student-admin-binding", labels },
        subjects: [
          { kind: "ServiceAccount", name: "default", namespace: ns },
          { kind: "ServiceAccount", name: "pipeline", namespace: ns },
        ],
        roleRef: {
          kind: "ClusterRole",
          name: "admin",
          apiGroup: "rbac.authorization.k8s.io",
        },
      },
    });

    // 4. ResourceQuota (from profile)
    const quotas = opts.spec.resources?.quotas || {};
    if (Object.keys(quotas).length > 0) {
      await coreApi.createNamespacedResourceQuota({
        namespace: ns,
        body: {
          apiVersion: "v1",
          kind: "ResourceQuota",
          metadata: { name: "student-quota", labels },
          spec: { hard: quotas },
        },
      });
    }

    // 5. LimitRange (from profile)
    const limits = opts.spec.resources?.limits || {};
    await coreApi.createNamespacedLimitRange({
      namespace: ns,
      body: {
        apiVersion: "v1",
        kind: "LimitRange",
        metadata: { name: "student-limits", labels },
        spec: {
          limits: [
            {
              default: {
                cpu: limits.defaultCpu || "500m",
                memory: limits.defaultMemory || "512Mi",
              },
              defaultRequest: {
                cpu: limits.defaultRequestCpu || "100m",
                memory: limits.defaultRequestMemory || "128Mi",
              },
              max: {
                cpu: limits.maxCpu || "1",
                memory: limits.maxMemory || "2Gi",
              },
              min: { cpu: "10m", memory: "32Mi" },
              type: "Container",
            },
            {
              max: { storage: "5Gi" },
              min: { storage: "1Gi" },
              type: "PersistentVolumeClaim",
            },
          ],
        },
      },
    });

    // 6. NetworkPolicy
    const allowNs = opts.spec.networkPolicies?.allowNamespaces || [
      "openshift-ingress",
      "openshift-monitoring",
    ];
    await networkingApi.createNamespacedNetworkPolicy({
      namespace: ns,
      body: {
        apiVersion: "networking.k8s.io/v1",
        kind: "NetworkPolicy",
        metadata: { name: "student-network-policy", labels },
        spec: {
          podSelector: {},
          policyTypes: ["Ingress", "Egress"],
          ingress: [
            ...allowNs.map((nsName: string) => ({
              from: [
                {
                  namespaceSelector: {
                    matchLabels: { name: nsName },
                  },
                },
              ],
            })),
            { from: [{ podSelector: {} }] },
          ],
          egress: [{}],
        },
      },
    });

    // 7. PVC
    const storageClass = opts.spec.storage?.storageClass || "gp3-csi";
    const pvcSize = opts.spec.storage?.workspacePvcSize || "1Gi";
    await coreApi.createNamespacedPersistentVolumeClaim({
      namespace: ns,
      body: {
        apiVersion: "v1",
        kind: "PersistentVolumeClaim",
        metadata: { name: "code-server-pvc", labels },
        spec: {
          accessModes: ["ReadWriteOnce"],
          resources: { requests: { storage: pvcSize } },
          storageClassName: storageClass,
        },
      },
    });

    // 8. Deployment
    const containerRes = opts.spec.containerResources || {
      requests: { cpu: "200m", memory: "256Mi" },
      limits: { cpu: "500m", memory: "512Mi" },
    };
    await appsApi.createNamespacedDeployment({
      namespace: ns,
      body: {
        apiVersion: "apps/v1",
        kind: "Deployment",
        metadata: { name: "code-server", labels },
        spec: {
          replicas: 1,
          selector: { matchLabels: { app: "code-server" } },
          template: {
            metadata: {
              labels: {
                app: "code-server",
                student: ns,
                profile: opts.profile,
              },
            },
            spec: {
              securityContext: { runAsNonRoot: true },
              containers: [
                {
                  name: "code-server",
                  image,
                  ports: [{ containerPort: 8080, protocol: "TCP" }],
                  env: [
                    { name: "PASSWORD", value: opts.password },
                    { name: "STUDENT_NAMESPACE", value: ns },
                  ],
                  resources: containerRes,
                  securityContext: {
                    allowPrivilegeEscalation: false,
                    runAsNonRoot: true,
                    capabilities: { drop: ["ALL"] },
                    seccompProfile: { type: "RuntimeDefault" },
                  },
                  volumeMounts: [
                    { name: "data", mountPath: "/home/coder/workspace" },
                    { name: "tool-packs", mountPath: "/opt/tool-packs" },
                  ],
                  livenessProbe: {
                    httpGet: { path: "/healthz", port: 8080 },
                    initialDelaySeconds: 30,
                    periodSeconds: 30,
                  },
                  readinessProbe: {
                    httpGet: { path: "/healthz", port: 8080 },
                    initialDelaySeconds: 5,
                    periodSeconds: 10,
                  },
                },
              ],
              volumes: [
                {
                  name: "data",
                  persistentVolumeClaim: { claimName: "code-server-pvc" },
                },
                { name: "tool-packs", emptyDir: {} },
              ],
            },
          },
        },
      },
    });

    // 9. Service
    await coreApi.createNamespacedService({
      namespace: ns,
      body: {
        apiVersion: "v1",
        kind: "Service",
        metadata: { name: "code-server", labels },
        spec: {
          selector: { app: "code-server" },
          ports: [{ protocol: "TCP", port: 80, targetPort: 8080 }],
        },
      },
    });

    // 10. Route (OpenShift only — skipped on plain k8s)
    let routeUrl: string | undefined;
    if (customApi) {
      const routeHost = `${ns}-code-server.${opts.clusterDomain}`;
      try {
        await customApi.createNamespacedCustomObject({
          group: "route.openshift.io",
          version: "v1",
          namespace: ns,
          plural: "routes",
          body: {
            apiVersion: "route.openshift.io/v1",
            kind: "Route",
            metadata: { name: "code-server", labels },
            spec: {
              host: routeHost,
              to: { kind: "Service", name: "code-server" },
              port: { targetPort: 8080 },
              tls: { termination: "edge" },
            },
          },
        });
        routeUrl = `https://${routeHost}`;
      } catch {
        // Not an OpenShift cluster — skip route creation
      }
    }

    return { success: true, namespace: ns, routeUrl };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error(`Failed to create student ${ns}:`, error);
    return { success: false, namespace: ns, error: msg };
  }
}

// ── Delete operations ───────────────────────────────────────────────

export interface DeleteResult {
  success: boolean;
  namespace: string;
  error?: string;
}

export async function deleteStudentEnvironment(
  namespace: string
): Promise<DeleteResult> {
  await clientReady;

  if (!k8sAvailable || !coreApi) {
    return { success: false, namespace, error: "Cluster not connected" };
  }

  try {
    await coreApi.deleteNamespace({ name: namespace });
    return { success: true, namespace };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error(`Failed to delete ${namespace}:`, error);
    return { success: false, namespace, error: msg };
  }
}

// ── Restart operations ──────────────────────────────────────────────

export interface RestartResult {
  success: boolean;
  namespace: string;
  deletedPod?: string;
  error?: string;
}

export async function restartStudentPod(
  namespace: string
): Promise<RestartResult> {
  await clientReady;

  if (!k8sAvailable || !coreApi) {
    return { success: false, namespace, error: "Cluster not connected" };
  }

  try {
    const pods = await coreApi.listNamespacedPod({
      namespace,
      labelSelector: "app=code-server",
    });

    if (pods.items.length === 0) {
      return { success: false, namespace, error: "No code-server pod found" };
    }

    const podName = pods.items[0].metadata?.name;
    if (!podName) {
      return { success: false, namespace, error: "Pod has no name" };
    }

    await coreApi.deleteNamespacedPod({ name: podName, namespace });
    return { success: true, namespace, deletedPod: podName };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error(`Failed to restart pod in ${namespace}:`, error);
    return { success: false, namespace, error: msg };
  }
}

// ── Stub data for development ───────────────────────────────────────

function getStubStudents(): StudentEnvironment[] {
  return [
    {
      name: "student01",
      namespace: "student01",
      profile: "devops-bootcamp",
      status: "running",
      podName: "code-server-abc123",
      podPhase: "Running",
      routeUrl: "https://student01-code-server.apps.example.com",
      createdAt: new Date().toISOString(),
    },
    {
      name: "student02",
      namespace: "student02",
      profile: "devops-bootcamp",
      status: "running",
      podName: "code-server-def456",
      podPhase: "Running",
      routeUrl: "https://student02-code-server.apps.example.com",
      createdAt: new Date().toISOString(),
    },
    {
      name: "student03",
      namespace: "student03",
      profile: "java-dev",
      status: "pending",
      podName: "code-server-ghi789",
      podPhase: "Pending",
      routeUrl: "https://student03-code-server.apps.example.com",
      createdAt: new Date().toISOString(),
    },
  ];
}
