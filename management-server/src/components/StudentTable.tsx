"use client";

import type { StudentEnvironment } from "@/lib/types";
import StatusBadge from "./StatusBadge";

interface StudentTableProps {
  students: StudentEnvironment[];
}

export default function StudentTable({ students }: StudentTableProps) {
  if (students.length === 0) {
    return <p style={{ color: "#6b7280" }}>No student environments found.</p>;
  }

  return (
    <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "14px" }}>
      <thead>
        <tr style={{ borderBottom: "2px solid #e5e7eb", textAlign: "left" }}>
          <th style={{ padding: "8px" }}>Student</th>
          <th style={{ padding: "8px" }}>Profile</th>
          <th style={{ padding: "8px" }}>Status</th>
          <th style={{ padding: "8px" }}>Pod</th>
          <th style={{ padding: "8px" }}>Created</th>
        </tr>
      </thead>
      <tbody>
        {students.map((student) => (
          <tr key={student.namespace} style={{ borderBottom: "1px solid #f3f4f6" }}>
            <td style={{ padding: "8px", fontWeight: 500 }}>
              <a href={`/students?ns=${student.namespace}`} style={{ color: "#2563eb" }}>
                {student.name}
              </a>
            </td>
            <td style={{ padding: "8px" }}>{student.profile}</td>
            <td style={{ padding: "8px" }}>
              <StatusBadge status={student.status} />
            </td>
            <td style={{ padding: "8px", fontFamily: "monospace", fontSize: "12px" }}>
              {student.podName || "-"}
            </td>
            <td style={{ padding: "8px", color: "#6b7280" }}>
              {student.createdAt
                ? new Date(student.createdAt).toLocaleDateString()
                : "-"}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
