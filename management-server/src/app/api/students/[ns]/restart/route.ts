import { NextRequest, NextResponse } from "next/server";
import { restartStudentPod } from "@/lib/openshift";
import { requireAdminMutationAuth } from "@/lib/api-auth";

const STUDENT_NAMESPACE_RE = /^student\d+$/;

// POST /api/students/[ns]/restart — restart the code-server pod
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ ns: string }> }
) {
  const authError = requireAdminMutationAuth(request);
  if (authError) {
    return authError;
  }

  const { ns } = await params;
  if (!STUDENT_NAMESPACE_RE.test(ns)) {
    return NextResponse.json(
      { error: "Invalid student namespace format" },
      { status: 400 }
    );
  }

  const result = await restartStudentPod(ns);

  if (result.success) {
    return NextResponse.json({
      message: `Restarted pod ${result.deletedPod} in ${ns}`,
      deletedPod: result.deletedPod,
    });
  }

  return NextResponse.json(
    { error: result.error || "Restart failed" },
    { status: 500 }
  );
}
