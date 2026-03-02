"use client";

import { useState } from "react";
import type { StudentEnvironment } from "@/lib/types";
import StatusBadge from "./StatusBadge";

interface StudentTableProps {
  students: StudentEnvironment[];
}

export default function StudentTable({ students }: StudentTableProps) {
  const [actionState, setActionState] = useState<
    Record<string, { loading: boolean; message?: string }>
  >({});

  if (students.length === 0) {
    return <p style={{ color: "#6b7280" }}>No student environments found.</p>;
  }

  async function handleRestart(ns: string) {
    setActionState((s) => ({ ...s, [ns]: { loading: true } }));
    try {
      const res = await fetch(`/api/students/${ns}/restart`, { method: "POST" });
      const data = await res.json();
      setActionState((s) => ({
        ...s,
        [ns]: { loading: false, message: res.ok ? "Restarting..." : data.error },
      }));
    } catch (err) {
      setActionState((s) => ({
        ...s,
        [ns]: { loading: false, message: String(err) },
      }));
    }
  }

  async function handleDelete(ns: string) {
    if (!confirm(`Delete student environment "${ns}"? This cannot be undone.`)) {
      return;
    }
    setActionState((s) => ({ ...s, [ns]: { loading: true } }));
    try {
      const res = await fetch(`/api/students/${ns}`, { method: "DELETE" });
      const data = await res.json();
      setActionState((s) => ({
        ...s,
        [ns]: {
          loading: false,
          message: res.ok ? "Deleting..." : data.error,
        },
      }));
      if (res.ok) {
        // Reload the page after a short delay to reflect the deletion
        setTimeout(() => window.location.reload(), 2000);
      }
    } catch (err) {
      setActionState((s) => ({
        ...s,
        [ns]: { loading: false, message: String(err) },
      }));
    }
  }

  const btnStyle = {
    padding: "3px 8px",
    border: "1px solid #d1d5db",
    borderRadius: "4px",
    fontSize: "12px",
    cursor: "pointer" as const,
    background: "white",
  };

  return (
    <table
      style={{ width: "100%", borderCollapse: "collapse", fontSize: "14px" }}
    >
      <thead>
        <tr style={{ borderBottom: "2px solid #e5e7eb", textAlign: "left" }}>
          <th style={{ padding: "8px" }}>Student</th>
          <th style={{ padding: "8px" }}>Profile</th>
          <th style={{ padding: "8px" }}>Status</th>
          <th style={{ padding: "8px" }}>Pod</th>
          <th style={{ padding: "8px" }}>Created</th>
          <th style={{ padding: "8px" }}>Actions</th>
        </tr>
      </thead>
      <tbody>
        {students.map((student) => {
          const state = actionState[student.namespace];
          return (
            <tr
              key={student.namespace}
              style={{ borderBottom: "1px solid #f3f4f6" }}
            >
              <td style={{ padding: "8px", fontWeight: 500 }}>
                {student.routeUrl ? (
                  <a
                    href={student.routeUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ color: "#2563eb" }}
                    title="Open code-server"
                  >
                    {student.name}
                  </a>
                ) : (
                  student.name
                )}
              </td>
              <td style={{ padding: "8px" }}>{student.profile}</td>
              <td style={{ padding: "8px" }}>
                <StatusBadge status={student.status} />
              </td>
              <td
                style={{
                  padding: "8px",
                  fontFamily: "monospace",
                  fontSize: "12px",
                }}
              >
                {student.podName || "-"}
              </td>
              <td style={{ padding: "8px", color: "#6b7280" }}>
                {student.createdAt
                  ? new Date(student.createdAt).toLocaleDateString()
                  : "-"}
              </td>
              <td style={{ padding: "8px" }}>
                {state?.loading ? (
                  <span style={{ color: "#6b7280", fontSize: "12px" }}>
                    Working...
                  </span>
                ) : state?.message ? (
                  <span
                    style={{
                      color: state.message.includes("...")
                        ? "#22c55e"
                        : "#ef4444",
                      fontSize: "12px",
                    }}
                  >
                    {state.message}
                  </span>
                ) : (
                  <span style={{ display: "flex", gap: "4px" }}>
                    {student.routeUrl && (
                      <a
                        href={student.routeUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{ ...btnStyle, textDecoration: "none", color: "#2563eb" }}
                      >
                        Open
                      </a>
                    )}
                    <button
                      onClick={() => handleRestart(student.namespace)}
                      style={{ ...btnStyle, color: "#f59e0b" }}
                      title="Restart the code-server pod"
                    >
                      Restart
                    </button>
                    <button
                      onClick={() => handleDelete(student.namespace)}
                      style={{ ...btnStyle, color: "#ef4444" }}
                      title="Delete this student environment"
                    >
                      Delete
                    </button>
                  </span>
                )}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
