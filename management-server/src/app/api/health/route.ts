import { NextResponse } from "next/server";
import { getClusterHealth } from "@/lib/openshift";

// GET /api/health — cluster health check
export async function GET() {
  const health = await getClusterHealth();
  return NextResponse.json(health);
}
