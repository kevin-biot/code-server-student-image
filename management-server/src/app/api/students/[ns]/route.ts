import { NextRequest, NextResponse } from "next/server";
import { getStudentStatus } from "@/lib/openshift";
import { teardownStudents } from "@/lib/admin-scripts";

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

// DELETE /api/students/[ns] — teardown a student environment
export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ ns: string }> }
) {
  const { ns } = await params;

  // Extract student number from namespace (e.g., student03 -> 3)
  const match = ns.match(/(\d+)$/);
  if (!match) {
    return NextResponse.json(
      { error: "Invalid student namespace format" },
      { status: 400 }
    );
  }

  const num = parseInt(match[1], 10);
  const result = await teardownStudents(num, num);

  if (result.success) {
    return NextResponse.json({ message: `Teardown initiated for ${ns}` });
  }

  return NextResponse.json(
    { error: "Teardown failed", stderr: result.stderr },
    { status: 500 }
  );
}
