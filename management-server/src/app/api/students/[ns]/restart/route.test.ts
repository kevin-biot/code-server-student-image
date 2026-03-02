import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { NextRequest } from "next/server";

vi.mock("@/lib/openshift", () => ({
  restartStudentPod: vi.fn(),
}));

import { POST } from "./route";
import { restartStudentPod } from "@/lib/openshift";

const mockRestartStudentPod = vi.mocked(restartStudentPod);

describe("POST /api/students/[ns]/restart", () => {
  const originalToken = process.env.MANAGEMENT_API_TOKEN;

  beforeEach(() => {
    process.env.MANAGEMENT_API_TOKEN = "secret-token";
    mockRestartStudentPod.mockReset();
  });

  afterEach(() => {
    process.env.MANAGEMENT_API_TOKEN = originalToken;
  });

  it("returns 401 when token is missing", async () => {
    const request = new NextRequest(
      "http://localhost/api/students/student01/restart",
      {
        method: "POST",
      }
    );

    const response = await POST(request, {
      params: Promise.resolve({ ns: "student01" }),
    });

    expect(response.status).toBe(401);
  });

  it("returns 400 for invalid namespace", async () => {
    const request = new NextRequest(
      "http://localhost/api/students/default/restart",
      {
        method: "POST",
        headers: { "x-management-token": "secret-token" },
      }
    );

    const response = await POST(request, {
      params: Promise.resolve({ ns: "default" }),
    });

    expect(response.status).toBe(400);
  });

  it("returns 200 when restart succeeds", async () => {
    mockRestartStudentPod.mockResolvedValue({
      success: true,
      namespace: "student01",
      deletedPod: "code-server-123",
    });

    const request = new NextRequest(
      "http://localhost/api/students/student01/restart",
      {
        method: "POST",
        headers: { "x-management-token": "secret-token" },
      }
    );

    const response = await POST(request, {
      params: Promise.resolve({ ns: "student01" }),
    });

    expect(response.status).toBe(200);
  });

  it("returns 500 when restart fails", async () => {
    mockRestartStudentPod.mockResolvedValue({
      success: false,
      namespace: "student01",
      error: "no pod",
    });

    const request = new NextRequest(
      "http://localhost/api/students/student01/restart",
      {
        method: "POST",
        headers: { "x-management-token": "secret-token" },
      }
    );

    const response = await POST(request, {
      params: Promise.resolve({ ns: "student01" }),
    });

    expect(response.status).toBe(500);
  });
});
