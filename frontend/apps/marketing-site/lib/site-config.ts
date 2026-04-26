/**
 * Zentrale Texte/URLs. Für Produktion per Umgebung überschreiben:
 * NEXT_PUBLIC_HELP_PHONE, NEXT_PUBLIC_HELP_PHONE_TEL, NEXT_PUBLIC_APP_URL, NEXT_PUBLIC_SUPPORT_EMAIL
 */
export const APP_NAME = "CallAgent"

export function getHelpPhoneDisplay(): string {
  return (process.env.NEXT_PUBLIC_HELP_PHONE ?? "+18145930475").trim()
}

/** z. B. tel:+498001234567 – immer wählbar, inkl. Ländervorwahl */
export function getHelpPhoneTelHref(): string {
  const raw = (process.env.NEXT_PUBLIC_HELP_PHONE_TEL ?? "").trim()
  if (raw) {
    if (raw.startsWith("tel:")) return raw
    return `tel:${raw.replace(/\s/g, "")}`
  }
  const d = getHelpPhoneDisplay().replace(/[^\d+]/g, "")
  if (d.startsWith("+")) return `tel:${d}`
  if (d.startsWith("0")) return `tel:+49${d.slice(1)}`
  return `tel:${d}`
}

export function getHelpHoursLine(): string {
  return (
    process.env.NEXT_PUBLIC_HELP_HOURS ??
    "Mo–Fr 8:00–20:00 Uhr · Anruf für Sie kostenfrei (Festnetz, ggf. Mobilfunk laut Anbieter)"
  ).trim()
}

export function getAppUrl(): string {
  const fromEnv = (process.env.NEXT_PUBLIC_APP_URL ?? "").trim()
  if (fromEnv) return fromEnv
  return "https://admin.eternacore.de"
}

export function getSupportEmail(): string {
  return (process.env.NEXT_PUBLIC_SUPPORT_EMAIL ?? "support@example.com").trim()
}

export function getSiteUrl(): string {
  return (process.env.NEXT_PUBLIC_SITE_URL ?? "https://callagent.app").trim()
}
