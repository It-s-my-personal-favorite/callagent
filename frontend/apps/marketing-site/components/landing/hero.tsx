"use client"

import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Activity, CheckCircle2, Headphones, Mic, Shield, Waves } from "lucide-react"
import { getAppUrl, getHelpPhoneDisplay, getHelpPhoneTelHref } from "@/lib/site-config"

export function Hero() {
  const helpTel = getHelpPhoneTelHref()
  const helpDisplay = getHelpPhoneDisplay()
  const appUrl = getAppUrl()

  return (
    <section className="relative flex items-center pt-14 sm:pt-16 overflow-hidden min-h-[88svh] sm:min-h-[100svh]">
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-1/4 left-1/4 w-64 h-64 sm:w-96 sm:h-96 bg-primary/20 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 right-1/4 w-64 h-64 sm:w-96 sm:h-96 bg-accent/20 rounded-full blur-3xl" />
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#1f1f1f_1px,transparent_1px),linear-gradient(to_bottom,#1f1f1f_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_110%)]" />
      </div>

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8 sm:py-16 lg:py-24 w-full">
        <div className="grid lg:grid-cols-2 gap-6 sm:gap-8 lg:gap-20 items-center">
          <div className="text-center lg:text-left">
            <Badge
              variant="outline"
              className="mb-3 sm:mb-4 px-2.5 sm:px-3 py-1 border-primary/50 text-primary text-[11px] sm:text-sm"
            >
              Admin · Telefonie · Voice-API
            </Badge>

            <h1 className="text-2xl sm:text-4xl lg:text-5xl xl:text-6xl font-bold tracking-tight leading-tight text-balance">
              Eingehende Anrufe professionell im Griff – mit{" "}
              <span className="gradient-text">CallAgent</span>
            </h1>

            <p className="mt-3 sm:mt-4 text-sm sm:text-lg text-muted-foreground leading-relaxed max-w-xl mx-auto lg:mx-0">
              Eine zentrale Oberfläche für Ihr Team: Live-Anrufe, Historie, Kundenkontext, Sperrlisten
              und Anbindung an Ihre Sprach-API. Transkripte, Aufzeichnungen und Reviews bleiben
              übersichtlich – damit jeder Kundenkontakt nachvollziehbar ist.
            </p>

            <div className="mt-5 sm:mt-6 flex flex-col sm:flex-row gap-2.5 sm:gap-3 justify-center lg:justify-start">
              <Button size="lg" className="bg-primary hover:bg-primary/90 text-primary-foreground px-6" asChild>
                <a href={helpTel} className="inline-flex items-center">
                  Hotline: {helpDisplay}
                </a>
              </Button>
              <Button size="lg" variant="outline" asChild>
                <a href={appUrl}>Zur Admin-App</a>
              </Button>
            </div>

            <div className="mt-6 flex flex-wrap gap-x-5 gap-y-2 justify-center lg:justify-start text-xs sm:text-sm text-muted-foreground">
              <div className="flex items-center gap-1.5">
                <Activity className="h-3.5 w-3.5 text-primary" />
                <span>Live-Status &amp; Polling</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Shield className="h-3.5 w-3.5 text-primary" />
                <span>Nummern sperren &amp; moderieren</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Waves className="h-3.5 w-3.5 text-primary" />
                <span>Audio &amp; Transkripte</span>
              </div>
            </div>
          </div>

          <div className="relative hidden sm:block">
            <div className="relative rounded-2xl border border-border/50 bg-card/50 p-2 shadow-2xl backdrop-blur-sm">
              <div className="flex items-center gap-2 px-3 py-2.5 border-b border-border/50">
                <div className="flex gap-1.5">
                  <div className="w-2.5 h-2.5 rounded-full bg-destructive/50" />
                  <div className="w-2.5 h-2.5 rounded-full bg-yellow-500/50" />
                  <div className="w-2.5 h-2.5 rounded-full bg-accent/50" />
                </div>
                <div className="flex-1 mx-3">
                  <div className="h-6 rounded-md bg-secondary/50 flex items-center px-2 text-xs text-muted-foreground">
                    callagent – Admin
                  </div>
                </div>
              </div>

              <div className="p-4 space-y-4">
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { label: "Live", value: "3", color: "text-primary" },
                    { label: "Heute", value: "24", color: "text-accent" },
                    { label: "Gesperrt", value: "2", color: "text-chart-4" },
                  ].map((stat) => (
                    <div key={stat.label} className="rounded-lg bg-secondary/30 p-3 text-center">
                      <div className={`text-xl font-bold ${stat.color}`}>{stat.value}</div>
                      <div className="text-xs text-muted-foreground mt-0.5">{stat.label}</div>
                    </div>
                  ))}
                </div>

                <div className="space-y-2">
                  {[
                    { name: "Eingang – Beratung", state: "Live", chip: "bg-primary/25 text-foreground" },
                    { name: "Rückruf – Rückfrage", state: "Beendet", chip: "bg-secondary text-secondary-foreground" },
                    { name: "Support – Rückgabe", state: "Wartet", chip: "bg-chart-4/30 text-foreground" },
                  ].map((row) => (
                    <div
                      key={row.name}
                      className="flex items-center justify-between p-2.5 rounded-lg bg-secondary/20 border border-border/30"
                    >
                      <div className="flex items-center gap-2 min-w-0">
                        <div className="w-7 h-7 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                          <Headphones className="h-3.5 w-3.5 text-primary" />
                        </div>
                        <div className="min-w-0">
                          <div className="text-xs font-medium truncate">{row.name}</div>
                          <div className="text-xs text-muted-foreground">Transkript · Aufnahme</div>
                        </div>
                      </div>
                      <span className={`text-[10px] px-2 py-0.5 rounded-md ${row.chip}`}>{row.state}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="absolute -bottom-4 -left-4 rounded-xl border border-border/50 bg-card p-3 shadow-xl backdrop-blur-sm max-w-[220px]">
              <div className="flex items-center gap-2.5">
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent/20">
                  <Mic className="h-4 w-4 text-accent" />
                </div>
                <div>
                  <div className="text-xs font-medium">Voice-API</div>
                  <div className="text-xs text-muted-foreground">Verbunden</div>
                </div>
                <CheckCircle2 className="h-4 w-4 text-accent ml-auto shrink-0" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
