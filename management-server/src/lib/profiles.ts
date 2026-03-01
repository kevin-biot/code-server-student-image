import { readFileSync, readdirSync, existsSync } from "fs";
import { join } from "path";
import { parse } from "yaml";
import type { TrainingProfile } from "./types";

// Profile directories are mounted or co-located relative to the management server
const PROFILES_DIR =
  process.env.PROFILES_DIR || join(process.cwd(), "..", "profiles");

export function listProfiles(): TrainingProfile[] {
  if (!existsSync(PROFILES_DIR)) {
    return [];
  }

  const entries = readdirSync(PROFILES_DIR, { withFileTypes: true });
  const profiles: TrainingProfile[] = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const profilePath = join(PROFILES_DIR, entry.name, "profile.yaml");
    if (!existsSync(profilePath)) continue;

    try {
      const content = readFileSync(profilePath, "utf-8");
      const profile = parse(content) as TrainingProfile;
      profiles.push(profile);
    } catch {
      console.error(`Failed to parse profile: ${entry.name}`);
    }
  }

  return profiles;
}

export function getProfile(name: string): TrainingProfile | null {
  const profilePath = join(PROFILES_DIR, name, "profile.yaml");
  if (!existsSync(profilePath)) return null;

  try {
    const content = readFileSync(profilePath, "utf-8");
    return parse(content) as TrainingProfile;
  } catch {
    return null;
  }
}

export function getProfileContentFiles(name: string): string[] {
  const contentDir = join(PROFILES_DIR, name, "content");
  if (!existsSync(contentDir)) return [];

  return readdirSync(contentDir).filter((f) => f.endsWith(".md"));
}

export function getProfileStartupScripts(name: string): string[] {
  const startupDir = join(PROFILES_DIR, name, "startup.d");
  if (!existsSync(startupDir)) return [];

  return readdirSync(startupDir)
    .filter((f) => f.endsWith(".sh"))
    .sort();
}

export function hasOverlay(name: string): boolean {
  const overlayDir =
    process.env.DEPLOY_DIR || join(process.cwd(), "..", "deploy");
  return existsSync(join(overlayDir, "overlays", name, "kustomization.yaml"));
}
