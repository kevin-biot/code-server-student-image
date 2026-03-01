"use client";

import { useState } from "react";
import type { TrainingProfile } from "@/lib/types";

interface DeploymentFormProps {
  profiles: TrainingProfile[];
}

export default function DeploymentForm({ profiles }: DeploymentFormProps) {
  const [profile, setProfile] = useState(profiles[0]?.metadata.name || "");
  const [startNum, setStartNum] = useState(1);
  const [endNum, setEndNum] = useState(5);
  const [clusterDomain, setClusterDomain] = useState("");
  const [password, setPassword] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleDeploy = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setStatus(null);

    try {
      const res = await fetch("/api/deploy", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ profile, startNum, endNum, clusterDomain, password }),
      });

      const data = await res.json();

      if (res.ok) {
        setStatus(`Deployed students ${startNum}-${endNum} with profile "${profile}"`);
      } else {
        setStatus(`Error: ${data.error || "Deployment failed"}`);
      }
    } catch (err) {
      setStatus(`Error: ${err instanceof Error ? err.message : "Unknown error"}`);
    } finally {
      setLoading(false);
    }
  };

  const inputStyle = {
    padding: "8px 12px",
    border: "1px solid #d1d5db",
    borderRadius: "6px",
    fontSize: "14px",
    width: "100%",
  };

  return (
    <form onSubmit={handleDeploy} style={{ maxWidth: "480px" }}>
      <div style={{ marginBottom: "16px" }}>
        <label style={{ display: "block", marginBottom: "4px", fontWeight: 500 }}>
          Profile
        </label>
        <select
          value={profile}
          onChange={(e) => setProfile(e.target.value)}
          style={inputStyle}
        >
          {profiles.map((p) => (
            <option key={p.metadata.name} value={p.metadata.name}>
              {p.metadata.name} — {p.metadata.description}
            </option>
          ))}
        </select>
      </div>

      <div style={{ display: "flex", gap: "12px", marginBottom: "16px" }}>
        <div style={{ flex: 1 }}>
          <label style={{ display: "block", marginBottom: "4px", fontWeight: 500 }}>
            Start #
          </label>
          <input
            type="number"
            min={1}
            max={99}
            value={startNum}
            onChange={(e) => setStartNum(Number(e.target.value))}
            style={inputStyle}
          />
        </div>
        <div style={{ flex: 1 }}>
          <label style={{ display: "block", marginBottom: "4px", fontWeight: 500 }}>
            End #
          </label>
          <input
            type="number"
            min={1}
            max={99}
            value={endNum}
            onChange={(e) => setEndNum(Number(e.target.value))}
            style={inputStyle}
          />
        </div>
      </div>

      <div style={{ marginBottom: "16px" }}>
        <label style={{ display: "block", marginBottom: "4px", fontWeight: 500 }}>
          Cluster Domain
        </label>
        <input
          type="text"
          placeholder="apps.cluster.example.com"
          value={clusterDomain}
          onChange={(e) => setClusterDomain(e.target.value)}
          required
          style={inputStyle}
        />
      </div>

      <div style={{ marginBottom: "16px" }}>
        <label style={{ display: "block", marginBottom: "4px", fontWeight: 500 }}>
          Student Password
        </label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          style={inputStyle}
        />
      </div>

      <button
        type="submit"
        disabled={loading}
        style={{
          padding: "10px 20px",
          background: loading ? "#9ca3af" : "#2563eb",
          color: "white",
          border: "none",
          borderRadius: "6px",
          fontSize: "14px",
          fontWeight: 600,
          cursor: loading ? "wait" : "pointer",
        }}
      >
        {loading ? "Deploying..." : `Deploy ${endNum - startNum + 1} Students`}
      </button>

      {status && (
        <p
          style={{
            marginTop: "12px",
            padding: "8px 12px",
            borderRadius: "6px",
            background: status.startsWith("Error") ? "#fef2f2" : "#f0fdf4",
            color: status.startsWith("Error") ? "#b91c1c" : "#166534",
          }}
        >
          {status}
        </p>
      )}
    </form>
  );
}
