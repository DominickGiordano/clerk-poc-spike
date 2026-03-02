import { verifyToken } from "@clerk/backend";
import { NextResponse } from "next/server";

export async function GET(req: Request) {
  const authHeader = req.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Missing token" }, { status: 401 });
  }

  const token = authHeader.slice(7);

  try {
    const payload = await verifyToken(token, {
      secretKey: process.env.CLERK_SECRET_KEY!,
    });

    return NextResponse.json({
      verified: true,
      clerk_id: payload.sub,
      email: (payload as Record<string, unknown>).email ?? null,
      org_id: (payload as Record<string, unknown>).org_id ?? null,
      org_role: (payload as Record<string, unknown>).org_role ?? null,
    });
  } catch {
    return NextResponse.json({ error: "Invalid token" }, { status: 401 });
  }
}
