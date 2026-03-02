// OpenShift/Kubernetes client wrapper.
// Uses @kubernetes/client-node v1.4.0+ (object-style params, no .body wrapper).

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

export interface K8sRoute {
  metadata?: K8sMeta;
  spec?: { host?: string };
}

// ── Typed API interfaces (v1.4.0 object-param style) ────────────────

export interface CoreV1Api {
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

export interface AppsV1Api {
  createNamespacedDeployment(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;
}

export interface NetworkingV1Api {
  createNamespacedNetworkPolicy(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;
}

export interface RbacV1Api {
  createNamespacedRoleBinding(opts: {
    namespace: string;
    body: unknown;
  }): Promise<unknown>;
}

export interface CustomObjectsApi {
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

export const clientReady = initClient();

export function getClientState() {
  return {
    k8sAvailable,
    coreApi,
    appsApi,
    networkingApi,
    rbacApi,
    customApi,
  };
}
