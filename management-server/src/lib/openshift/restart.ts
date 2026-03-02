import { clientReady, getClientState } from "./client";

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

  const { k8sAvailable, coreApi } = getClientState();
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
