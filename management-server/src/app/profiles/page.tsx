import ProfileCard from "@/components/ProfileCard";
import DeploymentForm from "@/components/DeploymentForm";
import { listProfiles, getProfileContentFiles, getProfileStartupScripts, hasOverlay } from "@/lib/profiles";

export default function ProfilesPage() {
  const profiles = listProfiles();

  const enriched = profiles.map((p) => ({
    ...p,
    contentFiles: getProfileContentFiles(p.metadata.name),
    startupScripts: getProfileStartupScripts(p.metadata.name),
    hasOverlay: hasOverlay(p.metadata.name),
  }));

  return (
    <div>
      <h1 style={{ fontSize: "24px", marginBottom: "24px" }}>Training Profiles</h1>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "32px" }}>
        <div>
          <h2 style={{ fontSize: "18px", marginBottom: "16px" }}>
            Available Profiles ({profiles.length})
          </h2>
          {enriched.map((profile) => (
            <ProfileCard key={profile.metadata.name} profile={profile} />
          ))}
        </div>

        <div>
          <h2 style={{ fontSize: "18px", marginBottom: "16px" }}>Deploy</h2>
          <DeploymentForm profiles={profiles} />
        </div>
      </div>
    </div>
  );
}
