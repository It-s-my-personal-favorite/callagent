"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Cookie, X, Settings, Check } from "lucide-react"
import Link from "next/link"

export function CookieConsent() {
  const [showBanner, setShowBanner] = useState(false)
  const [showSettings, setShowSettings] = useState(false)
  const [preferences, setPreferences] = useState({
    essential: true,
    functional: false,
    analytics: false,
    marketing: false,
  })

  useEffect(() => {
    const consent = localStorage.getItem("cookie-consent")
    if (!consent) {
      const timer = setTimeout(() => setShowBanner(true), 1000)
      return () => clearTimeout(timer)
    }
  }, [])

  const acceptAll = () => {
    const allAccepted = {
      essential: true,
      functional: true,
      analytics: true,
      marketing: true,
    }
    localStorage.setItem("cookie-consent", JSON.stringify(allAccepted))
    setShowBanner(false)
  }

  const acceptEssential = () => {
    const essentialOnly = {
      essential: true,
      functional: false,
      analytics: false,
      marketing: false,
    }
    localStorage.setItem("cookie-consent", JSON.stringify(essentialOnly))
    setShowBanner(false)
  }

  const savePreferences = () => {
    localStorage.setItem("cookie-consent", JSON.stringify(preferences))
    setShowBanner(false)
    setShowSettings(false)
  }

  if (!showBanner) return null

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 p-4 sm:p-6">
      <div className="mx-auto max-w-4xl">
        <div className="rounded-2xl border border-border bg-card shadow-2xl backdrop-blur-sm overflow-hidden">
          {!showSettings ? (
            <div className="p-6">
              <div className="flex items-start gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10">
                  <Cookie className="h-5 w-5 text-primary" />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-lg mb-2">Cookie-Einstellungen</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    Wir nutzen Cookies, um Ihre Erfahrung zu verbessern und unsere Dienste zu optimieren. 
                    Sie können wählen, welche Cookies Sie akzeptieren möchten.{" "}
                    <Link href="/datenschutz" className="text-primary hover:underline">
                      Mehr erfahren
                    </Link>
                  </p>
                </div>
                <button
                  onClick={() => setShowBanner(false)}
                  className="text-muted-foreground hover:text-foreground"
                  aria-label="Schließen"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              
              <div className="flex flex-col sm:flex-row gap-3 mt-6">
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={acceptEssential}
                >
                  Nur essenzielle
                </Button>
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => setShowSettings(true)}
                >
                  <Settings className="h-4 w-4 mr-2" />
                  Einstellungen
                </Button>
                <Button
                  className="flex-1 bg-primary hover:bg-primary/90 text-primary-foreground"
                  onClick={acceptAll}
                >
                  <Check className="h-4 w-4 mr-2" />
                  Alle akzeptieren
                </Button>
              </div>
            </div>
          ) : (
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="font-semibold text-lg">Cookie-Einstellungen</h3>
                <button
                  onClick={() => setShowSettings(false)}
                  className="text-muted-foreground hover:text-foreground"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              
              <div className="space-y-4">
                {[
                  {
                    key: "essential" as const,
                    label: "Essenzielle Cookies",
                    description: "Notwendig für die Grundfunktionen der Website.",
                    required: true,
                  },
                  {
                    key: "functional" as const,
                    label: "Funktionale Cookies",
                    description: "Ermöglichen erweiterte Funktionen und Personalisierung.",
                    required: false,
                  },
                  {
                    key: "analytics" as const,
                    label: "Analyse Cookies",
                    description: "Helfen uns, die Nutzung der Website zu verstehen.",
                    required: false,
                  },
                  {
                    key: "marketing" as const,
                    label: "Marketing Cookies",
                    description: "Werden verwendet, um Werbung relevanter zu gestalten.",
                    required: false,
                  },
                ].map((cookie) => (
                  <div
                    key={cookie.key}
                    className="flex items-center justify-between p-4 rounded-xl bg-secondary/30 border border-border/50"
                  >
                    <div>
                      <div className="font-medium">{cookie.label}</div>
                      <div className="text-sm text-muted-foreground">{cookie.description}</div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={preferences[cookie.key]}
                        onChange={(e) =>
                          !cookie.required &&
                          setPreferences({ ...preferences, [cookie.key]: e.target.checked })
                        }
                        disabled={cookie.required}
                        className="sr-only peer"
                      />
                      <div className={`w-11 h-6 rounded-full peer ${
                        cookie.required 
                          ? "bg-primary/50 cursor-not-allowed" 
                          : "bg-secondary peer-checked:bg-primary"
                      } peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/20 transition-colors after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-transform peer-checked:after:translate-x-5`} />
                    </label>
                  </div>
                ))}
              </div>
              
              <div className="flex gap-3 mt-6">
                <Button variant="outline" className="flex-1" onClick={() => setShowSettings(false)}>
                  Abbrechen
                </Button>
                <Button
                  className="flex-1 bg-primary hover:bg-primary/90 text-primary-foreground"
                  onClick={savePreferences}
                >
                  Einstellungen speichern
                </Button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
