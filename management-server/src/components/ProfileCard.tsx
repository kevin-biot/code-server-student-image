"use client";

import type { TrainingProfile } from "@/lib/types";

interface ProfileCardProps {
  profile: TrainingProfile & {
    contentFiles: string[];
    startupScripts: string[];
    hasOverlay: boolean;
  };
}

export default function ProfileCard({ profile }: ProfileCardProps) {
  const { metadata, spec } = profile;

  return (
    <div
      style={{
        border: "1px solid #e5e7eb",
        borderRadius: "8px",
        padding: "20px",
        marginBottom: "16px",
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h3 style={{ margin: 0, fontSize: "18px" }}>{metadata.name}</h3>
        <span style={{ fontSize: "12px", color: "#6b7280" }}>v{metadata.version}</span>
      </div>

      <p style={{ color: "#4b5563", margin: "8px 0" }}>{metadata.description}</p>

      <div style={{ display: "flex", gap: "6px", flexWrap: "wrap", marginBottom: "12px" }}>
        {metadata.tags.map((tag) => (
          <span
            key={tag}
            style={{
              background: "#eff6ff",
              color: "#1d4ed8",
              padding: "2px 8px",
              borderRadius: "4px",
              fontSize: "12px",
            }}
          >
            {tag}
          </span>
        ))}
      </div>

      <div style={{ fontSize: "14px", color: "#374151" }}>
        <p style={{ margin: "4px 0" }}>
          <strong>Tool packs:</strong> {spec.toolPacks.join(", ")}
        </p>
        <p style={{ margin: "4px 0" }}>
          <strong>Content files:</strong> {profile.contentFiles.length}
        </p>
        <p style={{ margin: "4px 0" }}>
          <strong>Startup scripts:</strong> {profile.startupScripts.length}
        </p>
        <p style={{ margin: "4px 0" }}>
          <strong>Kustomize overlay:</strong>{" "}
          {profile.hasOverlay ? "Ready" : "Not created"}
        </p>
        <p style={{ margin: "4px 0" }}>
          <strong>Resources:</strong> {spec.containerResources.requests.cpu} CPU /{" "}
          {spec.containerResources.requests.memory} RAM (request)
        </p>
      </div>
    </div>
  );
}
