import StudentTable from "@/components/StudentTable";
import type { StudentEnvironment, ClusterHealth } from "@/lib/types";

async function getHealth(): Promise<ClusterHealth> {
  try {
    const { getClusterHealth } = await import("@/lib/openshift");
    return getClusterHealth();
  } catch {
    return { connected: false, studentCount: 0, runningPods: 0, failedPods: 0, profiles: {} };
  }
}

async function getStudents(): Promise<StudentEnvironment[]> {
  try {
    const { listStudents } = await import("@/lib/openshift");
    return listStudents();
  } catch {
    return [];
  }
}

export default async function Dashboard() {
  const [health, students] = await Promise.all([getHealth(), getStudents()]);

  const statStyle = {
    padding: "16px 24px",
    border: "1px solid #e5e7eb",
    borderRadius: "8px",
    textAlign: "center" as const,
  };

  return (
    <div>
      <h1 style={{ fontSize: "24px", marginBottom: "24px" }}>Dashboard</h1>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "16px", marginBottom: "32px" }}>
        <div style={statStyle}>
          <div style={{ fontSize: "32px", fontWeight: 700 }}>{health.studentCount}</div>
          <div style={{ color: "#6b7280", fontSize: "14px" }}>Students</div>
        </div>
        <div style={statStyle}>
          <div style={{ fontSize: "32px", fontWeight: 700, color: "#22c55e" }}>{health.runningPods}</div>
          <div style={{ color: "#6b7280", fontSize: "14px" }}>Running</div>
        </div>
        <div style={statStyle}>
          <div style={{ fontSize: "32px", fontWeight: 700, color: health.failedPods > 0 ? "#ef4444" : "#6b7280" }}>
            {health.failedPods}
          </div>
          <div style={{ color: "#6b7280", fontSize: "14px" }}>Failed</div>
        </div>
        <div style={statStyle}>
          <div style={{ fontSize: "32px", fontWeight: 700 }}>
            {Object.keys(health.profiles).length}
          </div>
          <div style={{ color: "#6b7280", fontSize: "14px" }}>Profiles Active</div>
        </div>
      </div>

      {Object.keys(health.profiles).length > 0 && (
        <div style={{ marginBottom: "32px" }}>
          <h2 style={{ fontSize: "18px", marginBottom: "12px" }}>By Profile</h2>
          <div style={{ display: "flex", gap: "12px" }}>
            {Object.entries(health.profiles).map(([name, count]) => (
              <div
                key={name}
                style={{
                  padding: "8px 16px",
                  background: "#f3f4f6",
                  borderRadius: "6px",
                  fontSize: "14px",
                }}
              >
                <strong>{name}</strong>: {count}
              </div>
            ))}
          </div>
        </div>
      )}

      <h2 style={{ fontSize: "18px", marginBottom: "12px" }}>Student Environments</h2>
      <StudentTable students={students} />

      <div style={{ marginTop: "32px", padding: "16px", background: "#f8fafc", borderRadius: "8px", fontSize: "14px" }}>
        <strong>Cluster:</strong>{" "}
        {health.connected ? (
          <span style={{ color: "#22c55e" }}>Connected</span>
        ) : (
          <span style={{ color: "#6b7280" }}>Not connected (showing stub data)</span>
        )}
      </div>
    </div>
  );
}
