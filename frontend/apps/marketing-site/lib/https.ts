import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

function hostNoPort(host: string | null): string {
  if (!host) return ""
  return host.split(":")[0].toLowerCase()
}

function isLocalDevHost(host: string): boolean {
  return host === "localhost" || host === "127.0.0.1" || host.endsWith(".localhost")
}

/**
 * Client kam über HTTP (laut Proxy) → permanente Umleitung auf HTTPS.
 */
export function redirectHttpToHttps(request: NextRequest): NextResponse | null {
  if (process.env.NODE_ENV !== "production") return null
  const host =
    hostNoPort(request.headers.get("x-forwarded-host")) || hostNoPort(request.headers.get("host"))
  if (!host || isLocalDevHost(host)) return null
  const forwarded = request.headers.get("x-forwarded-proto")?.split(",")[0]?.trim()
  if (forwarded !== "http") return null
  const url = request.nextUrl.clone()
  url.protocol = "https:"
  return NextResponse.redirect(url, 308)
}
