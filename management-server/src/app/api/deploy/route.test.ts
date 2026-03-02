import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { NextRequest } from "next/server";

vi.mock("@/lib/openshift", () => ({
  createStudentEnvironment: vi.fn(),
}));

vi.mock("@/lib/profiles", () => ({
  getProfile: vi.fn(),
}));

import { POST } from "./route";
import { createStudentEnvironment } from "@/lib/openshift";
import { getProfile } from "@/lib/profiles";

const mockCreateStudentEnvironment = vi.mocked(createStudentEnvironment);
const mockGetProfile = vi.mocked(getProfile);

describe("POST /api/deploy", () => {
  const originalToken = process.env.MANAGEMENT_API_TOKEN;

  beforeEach(() => {
    process.env.MANAGEMENT_API_TOKEN = "secret-token";
    mockGetProfile.mockReset();
    mockCreateStudentEnvironment.mockReset();

    mockGetProfile.mockReturnValue({
      metadata: { name: "devops-bootcamp" },
      spec: {},
    } as any);
  });

  afterEach(() => {
    process.env.MANAGEMENT_API_TOKEN = originalToken;
  });

  it("returns 401 when token is missing", async () => {
    const request = new NextRequest("http://localhost/api/deploy", {
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

  it("deploys a range when token is valid", async () => {
    mockCreateStudentEnvironment
      .mockResolvedValueOnce({ success: true, namespace: "student01" })
      .mockResolvedValueOnce({ success: false, namespace: "student02", error: "boom" });

    const request = new NextRequest("http://localhost/api/deploy", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-management-token": "secret-token",
      },
      body: JSON.stringify({
        profile: "devops-bootcamp",
        startNum: 1,
        endNum: 2,
        clusterDomain: "apps.example.com",
        password: "pw",
      }),
    });

    const response = await POST(request);
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(mockCreateStudentEnvironment).toHaveBeenCalledTimes(2);
    expect(body.total).toBe(2);
    expect(body.succeeded).toBe(1);
    expect(body.failed).toBe(1);
  });
});
