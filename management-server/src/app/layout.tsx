import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Training Platform",
  description: "Management server for the training platform",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, -apple-system, sans-serif", color: "#111827" }}>
        <nav
          style={{
            background: "#1e293b",
            color: "white",
            padding: "12px 24px",
            display: "flex",
            gap: "24px",
            alignItems: "center",
          }}
        >
          <strong style={{ fontSize: "16px" }}>Training Platform</strong>
          <a href="/" style={{ color: "#94a3b8", textDecoration: "none", fontSize: "14px" }}>
            Dashboard
          </a>
          <a href="/profiles" style={{ color: "#94a3b8", textDecoration: "none", fontSize: "14px" }}>
            Profiles
          </a>
          <a href="/students" style={{ color: "#94a3b8", textDecoration: "none", fontSize: "14px" }}>
            Students
          </a>
        </nav>
        <main style={{ padding: "24px", maxWidth: "1200px", margin: "0 auto" }}>
          {children}
        </main>
      </body>
    </html>
  );
}
