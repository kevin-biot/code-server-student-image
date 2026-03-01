"use client";

interface StatusBadgeProps {
  status: "running" | "pending" | "failed" | "unknown";
}

const statusStyles: Record<string, string> = {
  running: "background: #22c55e; color: white",
  pending: "background: #f59e0b; color: white",
  failed: "background: #ef4444; color: white",
  unknown: "background: #6b7280; color: white",
};

export default function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <span
      style={{
        ...parseStyle(statusStyles[status] || statusStyles.unknown),
        padding: "2px 8px",
        borderRadius: "4px",
        fontSize: "12px",
        fontWeight: 600,
        textTransform: "uppercase",
      }}
    >
      {status}
    </span>
  );
}

function parseStyle(style: string): React.CSSProperties {
  const result: Record<string, string> = {};
  for (const part of style.split(";")) {
    const [key, value] = part.split(":").map((s) => s.trim());
    if (key && value) {
      result[key.replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = value;
    }
  }
  return result;
}
