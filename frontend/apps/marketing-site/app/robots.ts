import type { MetadataRoute } from "next"
import { getSiteUrl } from "@/lib/site-config"

export default function robots(): MetadataRoute.Robots {
  const siteUrl = getSiteUrl().replace(/\/$/, "")
  let host: string | undefined
  try {
    host = new URL(siteUrl).host
  } catch {
    host = undefined
  }
  return {
    rules: { userAgent: "*", allow: "/" },
    ...(host ? { host } : {}),
    sitemap: `${siteUrl}/sitemap.xml`,
  }
}
