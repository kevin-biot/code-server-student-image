import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { NextRequest } from "next/server";

vi.mock("@/lib/openshift", () => ({
  listStudents: vi.fn(),
  createStudentEnvironment: vi.fn(),
}));

vi.mock("@/lib/profiles", () => ({
  getProfile: vi.fn(),
}));

import { GET, POST } from "./route";
import { listStudents, createStudentEnvironment } from "@/lib/openshift";
import { getProfile } from "@/lib/profiles";

const mockListStudents = vi.mocked(listStudents);
const mockCreateStudentEnvironment = vi.mocked(createStudentEnvironment);
const mockGetProfile = vi.mocked(getProfile);

describe("/api/students", () => {
  const originalToken = process.env.MANAGEMENT_API_TOKEN;

  beforeEach(() => {
    process.env.MANAGEMENT_API_TOKEN = "secret-token";
    mockListStudents.mockReset();
    mockCreateStudentEnvironment.mockReset();
    mockGetProfile.mockReset();

    mockGetProfile.mockReturnValue({
      metadata: { name: "devops-bootcamp" },
      spec: {},
    } as any);
  });

  afterEach(() => {
    process.env.MANAGEMENT_API_TOKEN = originalToken;
  });

  it("GET returns student list", async () => {
    mockListStudents.mockResolvedValue([
      {
        name: "student01",
        namespace: "student01",
        profile: "devops-bootcamp",
        status: "running",
      },
    ] as any);

    const response = await GET();
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body).toHaveLength(1);
  });

  it("POST returns 401 when token is missing", async () => {
    const request = new NextRequest("http://localhost/api/students", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        profile: "devops-bootcamp",
        startNum: 1,
        endNum: 1,
        clusterDomain: "apps.example.com",
        password: "pw",
      }),
    });

    const response = await POST(request);
    expect(response.status).toBe(401);
  });

  it("POST creates selected students with valid token", async () => {
    mockCreateStudentEnvironment.mockResolvedValue({
      success: true,
      namespace: "student01",
    });

    const request = new NextRequest("http://localhost/api/students", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-management-token": "secret-token",
      },
      body: JSON.stringify({
        profile: "devops-bootcamp",
        startNum: 1,
        endNum: 1,
        clusterDomain: "apps.example.com",
        password: "pw",
      }),
    });

    const response = await POST(request);
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mockCreateStudentEnvironment).toHaveBeenCalledTimes(1);
    expect(body.results).toHaveLength(1);
  });
});
