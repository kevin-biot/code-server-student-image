import { NextRequest, NextResponse } from "next/server";

export const MANAGEMENT_TOKEN_HEADER = "x-management-token";

function readBearerToken(authorization: string | null): string | null {
  if (!authorization) {
    return null;
  }

  const [scheme, token] = authorization.trim().split(/\s+/, 2);
  if (!scheme || !token) {
    return null;
  }

  return scheme.toLowerCase() === "bearer" ? token : null;
}

export function requireAdminMutationAuth(
  request: NextRequest
): NextResponse | null {
  const expectedToken = process.env.MANAGEMENT_API_TOKEN;
  if (!expectedToken) {
    return null;
  }

  const providedToken =
    request.headers.get(MANAGEMENT_TOKEN_HEADER) ||
    readBearerToken(request.headers.get("authorization"));

  if (providedToken === expectedToken) {
    return null;
  }

  return NextResponse.json(
    {
      error:
        "Unauthorized: provide a valid management token via x-management-token or Authorization: Bearer",
    },
    { status: 401 }
  );
}
