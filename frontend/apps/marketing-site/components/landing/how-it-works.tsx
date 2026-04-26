"use client"

import { Badge } from "@/components/ui/badge"
import { Bot, LineChart, PhoneIncoming, Wrench } from "lucide-react"

const steps = [
  {
    number: "01",
    icon: Wrench,
    title: "Voice-System anbinden",
    description:
      "Hinterlegen Sie Ihre API-Basis, testen die Verbindung und betreiben das Backend in Ihrer kontrollierten Umgebung.",
  },
  {
    number: "02",
    icon: PhoneIncoming,
    title: "Anrufe laufen ein",
    description:
      "Eingehende Anrufe erscheinen in Live-Listen; Teams sehen, was gerade passiert, ohne Systeme wechseln zu müssen.",
  },
  {
    number: "03",
    icon: Bot,
    title: "KI & Sprachpfad",
    description:
      "Transkripte, Assistenten-Metadaten und Aufnahmen hängen an der Session – auswertbar in einem Detail-Panel.",
  },
  {
    number: "04",
    icon: LineChart,
    title: "Auswertung & Schutz",
    description:
      "Interne Reviews, Sperrlisten, PDF-Kurzbriefing und Monitoring helfen, Qualität und Sicherheit zu halten.",
  },
]

export function HowItWorks() {
  return (
    <section id="ablauf" className="py-10 sm:py-20 lg:py-28 scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-12">
          <Badge variant="outline" className="mb-3 border-primary/50 text-primary text-xs">
            Ablauf
          </Badge>
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-balance">
            Von der Anbindung bis zur Auswertung
          </h2>
          <p className="mt-3 text-sm sm:text-base text-muted-foreground">
            Kein Labyrinth – ein roter Faden für Ihre Telefon-Administration.
          </p>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-6">
          {steps.map((step, index) => (
            <div key={step.number} className="relative group">
              {index < steps.length - 1 && (
                <div className="hidden lg:block absolute top-10 left-[calc(50%+2rem)] w-[calc(100%-4rem)] h-px bg-gradient-to-r from-primary/50 to-transparent" />
              )}

              <div className="relative rounded-2xl border border-border/50 bg-card/50 p-3.5 sm:p-6 h-full transition-all duration-300 hover:border-primary/50 hover:bg-primary/5">
                <div className="absolute -top-2 -right-1 text-3xl sm:text-5xl font-bold text-primary/10 group-hover:text-primary/20 transition-colors select-none">
                  {step.number}
                </div>

                <div className="flex h-10 w-10 sm:h-12 sm:w-12 items-center justify-center rounded-xl bg-primary/10 border border-primary/20 mb-4 group-hover:bg-primary/20 transition-colors">
                  <step.icon className="h-5 w-5 sm:h-6 sm:w-6 text-primary" />
                </div>

                <h3 className="text-xs sm:text-base font-semibold mb-1.5 sm:mb-2">{step.title}</h3>
                <p className="text-[11px] sm:text-sm text-muted-foreground leading-relaxed">{step.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
