"use client"

import { Badge } from "@/components/ui/badge"
import { Keyboard, MousePointer2, Contrast, Captions } from "lucide-react"

const items = [
  {
    icon: Contrast,
    title: "Lesbare Oberfläche",
    text: "Die Admin-App nutzt klare Farben, ausreichend Kontrast und groß genug wählbare Bereiche – auch für erschwerte Sicht.",
  },
  {
    icon: Keyboard,
    title: "Bedienung",
    text: "Wesentliche Aktionen sind per Tastatur und Maus bzw. Touch erreichbar, wo die Plattform es zulässt.",
  },
  {
    icon: Captions,
    title: "Transkripte & Audio",
    text: "Gespräche können neben dem Mitschnitt mit Transkripten nachvollzogen werden – hilfreich für Nachlesen statt Wiederhören.",
  },
  {
    icon: MousePointer2,
    title: "Diese Seite",
    text: "Struktur mit Überschriften, Fokus sichtbar, Telefon-Links wählbar. Bei Screenreadern: Regionen followen der visuellen Reihenfolge.",
  },
]

export function AccessibilityLanding() {
  return (
    <section id="barrierefrei" className="py-10 sm:py-16 bg-secondary/20 scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-7 sm:mb-10">
          <Badge variant="outline" className="mb-3 border-primary/50 text-primary text-xs">
            Barrierefreiheit
          </Badge>
          <h2 className="text-2xl sm:text-3xl font-bold tracking-tight">Zugänglichkeit im Blick</h2>
          <p className="mt-2 text-sm sm:text-base text-muted-foreground">
            Technik ist nur dann gut, wenn sie für viele nutzbar ist. So unterstützen wir Orientierung
            und Klarheit – neben dem persönlichen Hilfetelefon.
          </p>
        </div>
        <div className="grid sm:grid-cols-2 gap-3 sm:gap-4 max-w-4xl mx-auto">
          {items.map((item) => (
            <div
              key={item.title}
              className="rounded-xl border border-border/50 bg-card/40 p-4 sm:p-5 flex gap-3"
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-secondary border border-border/50 shrink-0">
                <item.icon className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold text-sm sm:text-base mb-1">{item.title}</h3>
                <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">{item.text}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
