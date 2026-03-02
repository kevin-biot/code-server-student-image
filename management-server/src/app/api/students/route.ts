import { NextRequest, NextResponse } from "next/server";
import { listStudents, createStudentEnvironment } from "@/lib/openshift";
import { getProfile } from "@/lib/profiles";
import { requireAdminMutationAuth } from "@/lib/api-auth";
import type { DeployRequest } from "@/lib/types";

// GET /api/students — list all student environments
export async function GET() {
  const students = await listStudents();
  return NextResponse.json(students);
}

// POST /api/students — deploy student environments via k8s API
export async function POST(request: NextRequest) {
  const authError = requireAdminMutationAuth(request);
  if (authError) {
    return authError;
  }

  const body = (await request.json()) as DeployRequest;

  if (!body.profile || !body.clusterDomain || !body.password) {
    return NextResponse.json(
      { error: "Missing required fields: profile, clusterDomain, password" },
      { status: 400 }
    );
  }

  const profile = getProfile(body.profile);
  if (!profile) {
    return NextResponse.json(
      { error: `Profile '${body.profile}' not found` },
      { status: 404 }
    );
  }

  const startNum = body.startNum || 1;
  const endNum = body.endNum || 5;
  const results = [];

  for (let i = startNum; i <= endNum; i++) {
    const name = `student${String(i).padStart(2, "0")}`;
    const result = await createStudentEnvironment({
      name,
      profile: body.profile,
      clusterDomain: body.clusterDomain,
      password: body.password,
      spec: profile.spec,
    });
    results.push(result);
  }

  const succeeded = results.filter((r) => r.success).length;

  return NextResponse.json({
    message: `Deployed ${succeeded}/${results.length} students with profile ${body.profile}`,
    results,
  });
}
