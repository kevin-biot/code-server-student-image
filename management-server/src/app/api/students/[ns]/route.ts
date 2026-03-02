import { NextRequest, NextResponse } from "next/server";
import { getStudentStatus, deleteStudentEnvironment } from "@/lib/openshift";

const STUDENT_NAMESPACE_RE = /^student\d+$/;

// GET /api/students/[ns] — get status for a specific student
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ ns: string }> }
) {
  const { ns } = await params;
  const student = await getStudentStatus(ns);

  if (!student) {
    return NextResponse.json(
      { error: `Student ${ns} not found` },
      { status: 404 }
    );
  }

  return NextResponse.json(student);
}

// DELETE /api/students/[ns] — delete a student environment via k8s API
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ ns: string }> }
) {
  const { ns } = await params;
  if (!STUDENT_NAMESPACE_RE.test(ns)) {
    return NextResponse.json(
      { error: "Invalid student namespace format" },
      { status: 400 }
    );
  }

  const result = await deleteStudentEnvironment(ns);

  if (result.success) {
    return NextResponse.json({ message: `Deleted namespace ${ns}` });
  }

  return NextResponse.json(
    { error: result.error || "Delete failed" },
    { status: 500 }
  );
}
