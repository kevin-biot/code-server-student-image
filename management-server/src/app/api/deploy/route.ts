import { NextRequest, NextResponse } from "next/server";
import {
  createStudentEnvironment,
  type CreateResult,
} from "@/lib/openshift";
import { getProfile } from "@/lib/profiles";
import type { DeployRequest } from "@/lib/types";

// POST /api/deploy — bulk deploy students with a profile via k8s API
export async function POST(request: NextRequest) {
  const body = (await request.json()) as DeployRequest;

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

  const startNum = body.startNum || 1;
  const endNum = body.endNum || 5;
  const results: CreateResult[] = [];

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
  const failed = results.filter((r) => !r.success);

  return NextResponse.json({
    profile: profile.metadata.name,
    total: results.length,
    succeeded,
    failed: failed.length,
    results,
  });
}
