"use client"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Ear, HeartHandshake, Phone, Type, UserRound } from "lucide-react"
import { getHelpHoursLine, getHelpPhoneDisplay, getHelpPhoneTelHref, getSupportEmail } from "@/lib/site-config"

export function HelpHotline() {
  const tel = getHelpPhoneTelHref()
  const display = getHelpPhoneDisplay()
  const hours = getHelpHoursLine()
  const email = getSupportEmail()

  return (
    <section id="hilfe" className="py-10 sm:py-20 lg:py-24 scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-12">
          <Badge variant="outline" className="mb-3 border-primary/50 text-primary text-xs">
            Persönliche Hilfe
          </Badge>
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-balance">
            Direkt anrufen – wir nehmen uns Zeit
          </h2>
          <p className="mt-3 text-sm sm:text-base text-muted-foreground">
            Diese Nummer richtet sich besonders an ältere Menschen und an alle, die lieber sprechen als
            schreiben, oder die Unterstützung bei Einschränkungen brauchen. Unsere Mitarbeitenden
            erklären ruhig und verständlich, was CallAgent leistet und wie Sie Hilfe bekommen.
          </p>
        </div>

        <div className="max-w-2xl mx-auto">
          <Card className="border-primary/40 bg-primary/5 shadow-lg overflow-hidden">
            <CardHeader className="pb-2 sm:pb-4 text-center sm:text-left">
              <CardTitle className="text-xl sm:text-2xl flex flex-col sm:flex-row sm:items-center gap-2 justify-center sm:justify-start">
                <span className="inline-flex items-center justify-center gap-2">
                  <Phone className="h-6 w-6 text-primary shrink-0" aria-hidden />
                  Kostenfreie Hilfe-Hotline
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">Nummer zum direkten Wählen</p>
                  <a
                    href={tel}
                    className="text-3xl sm:text-4xl font-bold font-mono tabular-nums text-primary hover:underline break-all"
                    aria-label={`Hilfe anrufen unter ${display}`}
                  >
                    {display}
                  </a>
                  <p className="text-sm text-muted-foreground mt-2">{hours}</p>
                </div>
                <Button size="lg" className="w-full sm:w-auto shrink-0" asChild>
                  <a href={tel}>
                    <Phone className="h-4 w-4 mr-2" />
                    Jetzt anrufen
                  </a>
                </Button>
              </div>
              <p className="text-sm text-muted-foreground border-t border-border/60 pt-4">
                Wenn Sie lieber schreiben:{" "}
                <a className="text-primary font-medium hover:underline" href={`mailto:${email}`}>
                  {email}
                </a>
              </p>
            </CardContent>
          </Card>
        </div>

        <div className="mt-8 sm:mt-12 grid sm:grid-cols-2 gap-3 sm:gap-5 max-w-4xl mx-auto">
          {[
            {
              icon: Type,
              title: "Einfache Worte",
              text: "Wir vermeiden unnötig technische Begriffe. Auf Wunsch wiederholen wir Schritte langsam.",
            },
            {
              icon: UserRound,
              title: "Geduld & Respekt",
              text: "Kein Druck, keine Frist im Gespräch: Sie bestimmen das Tempo.",
            },
            {
              icon: Ear,
              title: "Zuhören",
              text: "Wir klären zuerst, was Sie brauchen – Anmeldung, Störung oder allgemeine Fragen.",
            },
            {
              icon: HeartHandshake,
              title: "Unterstützung bei Einschränkungen",
              text: "Sagen Sie uns, was hilft (z. B. lautere Sprache, Pausen). Wir richten uns danach.",
            },
          ].map((item) => (
            <div
              key={item.title}
              className="rounded-xl border border-border/50 bg-card/50 p-4 sm:p-5 flex gap-3"
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 border border-primary/20 shrink-0">
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
