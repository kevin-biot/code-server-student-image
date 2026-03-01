import { NextResponse } from "next/server";
import { listProfiles, getProfileContentFiles, getProfileStartupScripts, hasOverlay } from "@/lib/profiles";

export async function GET() {
  const profiles = listProfiles();

  const enriched = profiles.map((p) => ({
    ...p,
    contentFiles: getProfileContentFiles(p.metadata.name),
    startupScripts: getProfileStartupScripts(p.metadata.name),
    hasOverlay: hasOverlay(p.metadata.name),
  }));

  return NextResponse.json(enriched);
}
