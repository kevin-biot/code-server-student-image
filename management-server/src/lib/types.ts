// Types matching the TrainingProfile schema in profiles/profile-schema.yaml

export interface TrainingProfile {
  apiVersion: string;
  kind: "TrainingProfile";
  metadata: ProfileMetadata;
  spec: ProfileSpec;
}

export interface ProfileMetadata {
  name: string;
  description: string;
  version: string;
  tags: string[];
}

export interface ProfileSpec {
  toolPacks: string[];
  extensions: string[];
  content: ContentConfig;
  directoryStructure: string[];
  startupScripts: string[];
  envVars: Record<string, string>;
  resources: ResourceConfig;
  containerResources: ContainerResources;
  networkPolicies: NetworkPolicyConfig;
  rbac: RbacConfig;
  storage: StorageConfig;
}

export interface ContentConfig {
  configMapName: string;
  files: ContentFile[];
}

export interface ContentFile {
  source: string;
  destination: string;
}

export interface ResourceConfig {
  quotas: Record<string, string>;
  limits: Record<string, string>;
}

export interface ContainerResources {
  requests: { cpu: string; memory: string };
  limits: { cpu: string; memory: string };
}

export interface NetworkPolicyConfig {
  allowNamespaces: string[];
}

export interface RbacConfig {
  additionalRoleBindings?: RoleBindingConfig[];
  sccLevel: string;
}

export interface RoleBindingConfig {
  namespace: string;
  subjects: { kind: string; name: string }[];
  roleRef: string;
}

export interface StorageConfig {
  workspacePvcSize: string;
  storageClass: string;
  additionalPvcs?: AdditionalPvc[];
}

export interface AdditionalPvc {
  name: string;
  size: string;
  labels: Record<string, string>;
}

// Runtime types

export interface StudentEnvironment {
  name: string;
  namespace: string;
  profile: string;
  status: "running" | "pending" | "failed" | "unknown";
  podName?: string;
  podPhase?: string;
  routeUrl?: string;
  createdAt?: string;
}

export interface DeployRequest {
  profile: string;
  startNum: number;
  endNum: number;
  clusterDomain: string;
  password: string;
}

export interface ClusterHealth {
  connected: boolean;
  studentCount: number;
  runningPods: number;
  failedPods: number;
  profiles: Record<string, number>;
}
