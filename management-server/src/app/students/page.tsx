import StudentTable from "@/components/StudentTable";
import type { StudentEnvironment } from "@/lib/types";

async function getStudents(): Promise<StudentEnvironment[]> {
  try {
    const { listStudents } = await import("@/lib/openshift");
    return listStudents();
  } catch {
    return [];
  }
}

export default async function StudentsPage() {
  const students = await getStudents();

  const running = students.filter((s) => s.status === "running").length;
  const pending = students.filter((s) => s.status === "pending").length;
  const failed = students.filter((s) => s.status === "failed").length;

  return (
    <div>
      <h1 style={{ fontSize: "24px", marginBottom: "8px" }}>Student Environments</h1>

      <p style={{ color: "#6b7280", marginBottom: "24px" }}>
        {students.length} total &middot;{" "}
        <span style={{ color: "#22c55e" }}>{running} running</span> &middot;{" "}
        <span style={{ color: "#f59e0b" }}>{pending} pending</span> &middot;{" "}
        <span style={{ color: "#ef4444" }}>{failed} failed</span>
      </p>

      <StudentTable students={students} />

      <div style={{ marginTop: "24px", fontSize: "14px", color: "#6b7280" }}>
        <h3 style={{ fontSize: "14px", marginBottom: "8px" }}>API Endpoints</h3>
        <ul style={{ margin: 0, paddingLeft: "20px" }}>
          <li>
            <code>GET /api/students</code> — List all students
          </li>
          <li>
            <code>GET /api/students/[ns]</code> — Get student status
          </li>
          <li>
            <code>POST /api/students</code> — Deploy students
          </li>
          <li>
            <code>DELETE /api/students/[ns]</code> — Teardown student
          </li>
        </ul>
      </div>
    </div>
  );
}
