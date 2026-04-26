"use client"

import dynamic from "next/dynamic"
import { useEffect, useState } from "react"

const Analytics = dynamic(
  () => import("@vercel/analytics/next").then((m) => ({ default: m.Analytics })),
  { ssr: false },
)

function scheduleIdle(cb: () => void) {
  if (typeof requestIdleCallback !== "undefined") {
    const id = requestIdleCallback(cb, { timeout: 4000 })
    return () => cancelIdleCallback(id)
  }
  const id = window.setTimeout(cb, 1)
  return () => window.clearTimeout(id)
}

/** Lädt Analytics nach Leerlauf – weniger TBT beim ersten Paint. */
export function VercelAnalytics() {
  const [ready, setReady] = useState(false)

  useEffect(() => {
    return scheduleIdle(() => setReady(true))
  }, [])

  if (!ready) return null
  return <Analytics />
}
