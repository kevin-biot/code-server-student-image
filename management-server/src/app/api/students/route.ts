import { NextRequest, NextResponse } from "next/server";
import { listStudents } from "@/lib/openshift";
import { deployStudents } from "@/lib/admin-scripts";
import type { DeployRequest } from "@/lib/types";

// GET /api/students — list all student environments
export async function GET() {
  const students = await listStudents();
  return NextResponse.json(students);
}

// POST /api/students — deploy student environments
export async function POST(request: NextRequest) {
  const body = (await request.json()) as DeployRequest;

  if (!body.profile || !body.clusterDomain || !body.password) {
    return NextResponse.json(
      { error: "Missing required fields: profile, clusterDomain, password" },
      { status: 400 }
    );
  }

  const req: DeployRequest = {
    profile: body.profile,
    startNum: body.startNum || 1,
    endNum: body.endNum || 5,
    clusterDomain: body.clusterDomain,
    password: body.password,
  };

  const result = await deployStudents(req);

  if (result.success) {
    return NextResponse.json({
      message: `Deployed students ${req.startNum}-${req.endNum} with profile ${req.profile}`,
      stdout: result.stdout,
    });
  }

  return NextResponse.json(
    { error: "Deployment failed", stderr: result.stderr, stdout: result.stdout },
    { status: 500 }
  );
}
