import type { MetadataRoute } from "next"
import { getSiteUrl } from "@/lib/site-config"

export default function sitemap(): MetadataRoute.Sitemap {
  const base = getSiteUrl().replace(/\/$/, "")
  const now = new Date()
  const paths = [
    { path: "/", changeFrequency: "weekly" as const, priority: 1 },
    { path: "/impressum", changeFrequency: "yearly" as const, priority: 0.4 },
    { path: "/datenschutz", changeFrequency: "yearly" as const, priority: 0.4 },
    { path: "/agb", changeFrequency: "yearly" as const, priority: 0.4 },
  ]
  return paths.map(({ path, changeFrequency, priority }) => ({
    url: `${base}${path}`,
    lastModified: now,
    changeFrequency,
    priority,
  }))
}
