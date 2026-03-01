import { execFile } from "child_process";
import { join } from "path";
import type { DeployRequest } from "./types";

// Wrapper around admin shell scripts
// Scripts are mounted or co-located relative to the management server

const ADMIN_DIR =
  process.env.ADMIN_DIR || join(process.cwd(), "..", "admin");
const DEPLOY_DIR =
  process.env.DEPLOY_DIR || join(process.cwd(), "..", "deploy");

interface ScriptResult {
  success: boolean;
  stdout: string;
  stderr: string;
  exitCode: number;
}

function runScript(
  script: string,
  args: string[],
  env?: Record<string, string>
): Promise<ScriptResult> {
  return new Promise((resolve) => {
    const childEnv = { ...process.env, ...env };

    execFile(
      script,
      args,
      { env: childEnv, timeout: 300_000, maxBuffer: 10 * 1024 * 1024 },
      (error, stdout, stderr) => {
        resolve({
          success: !error,
          stdout: stdout || "",
          stderr: stderr || "",
          exitCode: error?.code ? Number(error.code) : 0,
        });
      }
    );
  });
}

export async function deployStudents(
  request: DeployRequest
): Promise<ScriptResult> {
  const script = join(ADMIN_DIR, "deploy", "deploy-profile.sh");

  return runScript(
    script,
    [
      "--profile",
      request.profile,
      "--start",
      String(request.startNum),
      "--end",
      String(request.endNum),
      "--domain",
      request.clusterDomain,
    ],
    {
      SHARED_PASSWORD: request.password,
      CLUSTER_DOMAIN: request.clusterDomain,
    }
  );
}

export async function teardownStudents(
  startNum: number,
  endNum: number
): Promise<ScriptResult> {
  const script = join(ADMIN_DIR, "manage", "teardown-students.sh");
  return runScript(script, [String(startNum), String(endNum)]);
}

export async function generateOverlay(
  profile: string,
  studentName: string,
  clusterDomain: string,
  password: string
): Promise<ScriptResult> {
  const script = join(DEPLOY_DIR, "generate-overlay.sh");
  return runScript(script, [profile, studentName, clusterDomain, password]);
}

export async function validateProfiles(): Promise<ScriptResult> {
  const script = join(process.cwd(), "..", "tests", "test-profile.sh");
  return runScript(script, []);
}

export async function runLint(): Promise<ScriptResult> {
  const script = join(process.cwd(), "..", "tests", "lint.sh");
  return runScript(script, []);
}
