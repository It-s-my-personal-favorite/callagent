import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"
import { redirectHttpToHttps } from "@/lib/https"

export function middleware(request: NextRequest) {
  return redirectHttpToHttps(request) ?? NextResponse.next()
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|icon.ico|icon.png|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|xml|txt|webmanifest)).*)",
  ],
}
