import type { ProfileSpec } from "../types";
import { clientReady, getClientState } from "./client";

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
  alreadyExisted?: boolean;
}

export async function createStudentEnvironment(
  opts: CreateStudentOpts
): Promise<CreateResult> {
  await clientReady;

  const { k8sAvailable, coreApi, appsApi, rbacApi, networkingApi, customApi } =
    getClientState();

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

  let alreadyExisted = false;

  try {
    alreadyExisted =
      (await createOrIgnoreExists(() =>
        coreApi.createNamespace({
          body: {
            apiVersion: "v1",
            kind: "Namespace",
            metadata: { name: ns, labels },
          },
        })
      )) || alreadyExisted;

    alreadyExisted =
      (await createOrIgnoreExists(() =>
        coreApi.createNamespacedServiceAccount({
          namespace: ns,
          body: {
            apiVersion: "v1",
            kind: "ServiceAccount",
            metadata: {
              name: "pipeline",
              labels: { ...labels, app: "tekton" },
            },
          },
        })
      )) || alreadyExisted;

    alreadyExisted =
      (await createOrIgnoreExists(() =>
        rbacApi.createNamespacedRoleBinding({
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
        })
      )) || alreadyExisted;

    const quotas = opts.spec.resources?.quotas || {};
    if (Object.keys(quotas).length > 0) {
      alreadyExisted =
        (await createOrIgnoreExists(() =>
          coreApi.createNamespacedResourceQuota({
            namespace: ns,
            body: {
              apiVersion: "v1",
              kind: "ResourceQuota",
              metadata: { name: "student-quota", labels },
              spec: { hard: quotas },
            },
          })
        )) || alreadyExisted;
    }

    const limits = opts.spec.resources?.limits || {};
    alreadyExisted =
      (await createOrIgnoreExists(() =>
        coreApi.createNamespacedLimitRange({
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
        })
      )) || alreadyExisted;

    const allowNs = opts.spec.networkPolicies?.allowNamespaces || [
      "openshift-ingress",
      "openshift-monitoring",
    ];
    alreadyExisted =
      (await createOrIgnoreExists(() =>
        networkingApi.createNamespacedNetworkPolicy({
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
                        matchLabels: {
                          "kubernetes.io/metadata.name": nsName,
                        },
                      },
                    },
                  ],
                })),
                { from: [{ podSelector: {} }] },
              ],
              egress: [{}],
            },
          },
        })
      )) || alreadyExisted;

    const storageClass = opts.spec.storage?.storageClass || "gp3-csi";
    const pvcSize = opts.spec.storage?.workspacePvcSize || "1Gi";
    alreadyExisted =
      (await createOrIgnoreExists(() =>
        coreApi.createNamespacedPersistentVolumeClaim({
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
        })
      )) || alreadyExisted;

    const containerRes = opts.spec.containerResources || {
      requests: { cpu: "200m", memory: "256Mi" },
      limits: { cpu: "500m", memory: "512Mi" },
    };
    alreadyExisted =
      (await createOrIgnoreExists(() =>
        appsApi.createNamespacedDeployment({
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
        })
      )) || alreadyExisted;

    alreadyExisted =
      (await createOrIgnoreExists(() =>
        coreApi.createNamespacedService({
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
        })
      )) || alreadyExisted;

    let routeUrl: string | undefined;
    if (customApi) {
      const routeHost = `${ns}-code-server.${opts.clusterDomain}`;
      try {
        alreadyExisted =
          (await createOrIgnoreExists(() =>
            customApi.createNamespacedCustomObject({
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
            })
          )) || alreadyExisted;
        routeUrl = `https://${routeHost}`;
      } catch {
        // Not an OpenShift cluster — skip route creation
      }
    }

    return { success: true, namespace: ns, routeUrl, alreadyExisted };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error(`Failed to create student ${ns}:`, error);
    return { success: false, namespace: ns, error: msg };
  }
}

async function createOrIgnoreExists(
  createFn: () => Promise<unknown>
): Promise<boolean> {
  try {
    await createFn();
    return false;
  } catch (error) {
    if (isAlreadyExistsError(error)) {
      return true;
    }
    throw error;
  }
}

function isAlreadyExistsError(error: unknown): boolean {
  if (!error || typeof error !== "object") {
    return false;
  }

  const maybe = error as {
    statusCode?: number;
    body?: {
      code?: number;
      reason?: string;
      message?: string;
    };
    response?: {
      statusCode?: number;
    };
    message?: string;
  };

  if (
    maybe.statusCode === 409 ||
    maybe.response?.statusCode === 409 ||
    maybe.body?.code === 409
  ) {
    return true;
  }

  if (maybe.body?.reason === "AlreadyExists") {
    return true;
  }

  const message = `${maybe.message || ""} ${maybe.body?.message || ""}`;
  return message.includes("AlreadyExists");
}
