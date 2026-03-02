import { clientReady, getClientState } from "./client";

export interface DeleteResult {
  success: boolean;
  namespace: string;
  error?: string;
}

export async function deleteStudentEnvironment(
  namespace: string
): Promise<DeleteResult> {
  await clientReady;

  const { k8sAvailable, coreApi } = getClientState();
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
