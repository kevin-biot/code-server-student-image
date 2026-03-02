import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { NextRequest } from "next/server";

vi.mock("@/lib/openshift", () => ({
  getStudentStatus: vi.fn(),
  deleteStudentEnvironment: vi.fn(),
}));

import { GET, DELETE } from "./route";
import { getStudentStatus, deleteStudentEnvironment } from "@/lib/openshift";

const mockGetStudentStatus = vi.mocked(getStudentStatus);
const mockDeleteStudentEnvironment = vi.mocked(deleteStudentEnvironment);

describe("/api/students/[ns]", () => {
  const originalToken = process.env.MANAGEMENT_API_TOKEN;

  beforeEach(() => {
    process.env.MANAGEMENT_API_TOKEN = "secret-token";
    mockGetStudentStatus.mockReset();
    mockDeleteStudentEnvironment.mockReset();
  });

  afterEach(() => {
    process.env.MANAGEMENT_API_TOKEN = originalToken;
  });

  it("GET returns 404 when student does not exist", async () => {
    mockGetStudentStatus.mockResolvedValue(null);

    const request = new NextRequest("http://localhost/api/students/student99");
    const response = await GET(request, {
      params: Promise.resolve({ ns: "student99" }),
    });

    expect(response.status).toBe(404);
  });

  it("DELETE returns 401 when token is missing", async () => {
    const request = new NextRequest("http://localhost/api/students/student01", {
      method: "DELETE",
    });

    const response = await DELETE(request, {
      params: Promise.resolve({ ns: "student01" }),
    });

    expect(response.status).toBe(401);
  });

  it("DELETE returns 400 for invalid namespace", async () => {
    const request = new NextRequest("http://localhost/api/students/default", {
      method: "DELETE",
      headers: { "x-management-token": "secret-token" },
    });

    const response = await DELETE(request, {
      params: Promise.resolve({ ns: "default" }),
    });

    expect(response.status).toBe(400);
  });

  it("DELETE returns 200 when deletion succeeds", async () => {
    mockDeleteStudentEnvironment.mockResolvedValue({
      success: true,
      namespace: "student01",
    });

    const request = new NextRequest("http://localhost/api/students/student01", {
      method: "DELETE",
      headers: { "x-management-token": "secret-token" },
    });

    const response = await DELETE(request, {
      params: Promise.resolve({ ns: "student01" }),
    });

    expect(response.status).toBe(200);
  });

  it("DELETE returns 500 when deletion fails", async () => {
    mockDeleteStudentEnvironment.mockResolvedValue({
      success: false,
      namespace: "student01",
      error: "boom",
    });

    const request = new NextRequest("http://localhost/api/students/student01", {
      method: "DELETE",
      headers: { "x-management-token": "secret-token" },
    });

    const response = await DELETE(request, {
      params: Promise.resolve({ ns: "student01" }),
    });

    expect(response.status).toBe(500);
  });
});
