import { NextRequest, NextResponse } from "next/server";
import { deployStudents } from "@/lib/admin-scripts";
import { getProfile } from "@/lib/profiles";
import type { DeployRequest } from "@/lib/types";

// POST /api/deploy — bulk deploy students with a profile
export async function POST(request: NextRequest) {
  const body = (await request.json()) as DeployRequest;

  // Validate profile exists
  const profile = getProfile(body.profile);
  if (!profile) {
    return NextResponse.json(
      { error: `Profile '${body.profile}' not found` },
      { status: 404 }
    );
  }

  if (!body.clusterDomain) {
    return NextResponse.json(
      { error: "clusterDomain is required" },
      { status: 400 }
    );
  }

  if (!body.password) {
    return NextResponse.json(
      { error: "password is required" },
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

  return NextResponse.json({
    success: result.success,
    profile: profile.metadata.name,
    students: { start: req.startNum, end: req.endNum },
    stdout: result.stdout,
    stderr: result.stderr,
  });
}
