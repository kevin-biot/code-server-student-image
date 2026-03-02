import type { StudentEnvironment } from "../types";

export function getStubStudents(): StudentEnvironment[] {
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
