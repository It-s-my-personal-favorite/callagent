import type { Metadata } from "next"
import { Header } from "@/components/landing/header"
import { Footer } from "@/components/landing/footer"
import Link from "next/link"
import { ArrowLeft } from "lucide-react"
import { Button } from "@/components/ui/button"

export const metadata: Metadata = {
  title: "AGB – CallAgent",
  description: "Allgemeine Geschäftsbedingungen der CallAgent-Software bzw. -dienste",
}

export default function AgbPage() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="pt-24 pb-16">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <Button variant="ghost" size="sm" className="mb-8" asChild>
            <Link href="/">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Zurück zur Startseite
            </Link>
          </Button>

          <h1 className="text-4xl font-bold tracking-tight mb-12">Allgemeine Geschäftsbedingungen (AGB)</h1>

          <div className="space-y-8">
            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">1. Geltungsbereich</h2>
              <p className="text-muted-foreground leading-relaxed">
                Diese AGB regeln die Bereitstellung und Nutzung der Software bzw. Dienstleistungen
                „CallAgent“ (Admin-Telefon-Anwendung inkl. angeschlossener Komponenten), soweit
                zwischen Anbieter und Kunde/Organisation schriftlich oder per Angebot nichts
                Abweichendes vereinbart ist.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">2. Leistungsgegenstand</h2>
              <p className="text-muted-foreground leading-relaxed">
                CallAgent stellt Werkzeuge zur Verwaltung eingehender Anrufe, zur Einsicht in
                Historie, Kundenkontext, Transkripte, Aufnahmen, Moderation/ Sperrungen sowie
                Anbindung an Voice-/Server-Backends zur Verfügung. Umfang, Umgebung (Cloud,
                On-Premise) und Service-Level ergeben sich aus Angebot bzw. Lizenzvereinbarung.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">3. Mitwirkung und Telefonie</h2>
              <p className="text-muted-foreground leading-relaxed">
                Der Kunde stellt geeignete Rechte an Rufnummern, zulässige Verarbeitung
                personenbezogener Daten, Netz- und API-Zugänge sowie rechtssichere Konfiguration
                (z. B. Mitarbeiter-Information, Auftragsverarbeitung) sicher. CallAgent ersetzt
                keine rechtliche Beratung zu Telekommunikations- und Datenschutzrecht.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">4. Nutzung und Sorgfalt</h2>
              <p className="text-muted-foreground leading-relaxed">
                Zugangsdaten sind geheim zu halten. Eine missbräuchliche Nutzung (z. B. unbefugter
                Zugriff auf Kundendaten, Umgehung technischer Sicherheiten) ist untersagt. Der
                Kunde informiert berechtigte Endnutzer über erlaubte Verarbeitung.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">5. Vergütung und Laufzeit</h2>
              <p className="text-muted-foreground leading-relaxed">
                Preise, Abrechnungsmodelle, Testphasen und Kündigungsfristen richten sich nach dem
                jeweiligen Angebot. Ohne anderes laufende Dienstleistungsverhältnis gelten ausschließlich
                diese AGB in ihrer jeweils aktuellen, auf der Website hinterlegten Fassung.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">6. Haftung</h2>
              <p className="text-muted-foreground leading-relaxed">
                Es gilt deutsches Recht. Die Haftung richtet sich nach den gesetzlichen Vorgaben; bei
                vorsätzlichem und grob fahrlässigem Verhalten unbeschränkt, bei leichter Fahrlässigkeit
                beschränkt auf typische, vorhersehbare Schäden. Ein Ausschluss greift nicht bei
                Verletzung des Lebens, des Körpers oder der Gesundheit, bei grob fahrlässiger
                Pflichtverletzung oder zugesicherten Eigenschaften.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">7. Schlussbestimmungen</h2>
              <p className="text-muted-foreground leading-relaxed">
                Sollte eine Bestimmung unwirksam sein, bleibt die Wirksamkeit der übrigen unberührt.
                Gerichtsstand ist, sofern der Kunde Kaufmann, juristische Person des öffentlichen
                Rechts oder Sondervermögen des öffentlichen Rechts ist, der Sitz des Anbieters.
                <br />
                <em>Stand: April 2026</em>
              </p>
            </section>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
