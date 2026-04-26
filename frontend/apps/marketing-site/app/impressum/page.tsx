import { Header } from "@/components/landing/header"
import { Footer } from "@/components/landing/footer"
import Link from "next/link"
import { ArrowLeft } from "lucide-react"
import { Button } from "@/components/ui/button"
import type { Metadata } from "next"
import { getSiteUrl, getSupportEmail } from "@/lib/site-config"

export const metadata: Metadata = {
  title: "Impressum – CallAgent",
  description: "Impressum und rechtliche Informationen zu CallAgent",
}

export default function ImpressumPage() {
  const email = getSupportEmail()
  const site = getSiteUrl()
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

          <h1 className="text-4xl font-bold tracking-tight mb-12">Impressum</h1>

          <div className="space-y-8">
            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">Anbieterkennzeichnung gemäß § 5 TMG</h2>
              <p className="text-muted-foreground leading-relaxed">
                CallAgent<br />
                Inhaber: Leandro Moreira<br />
                Musterstraße 1<br />
                12345 Musterstadt<br />
                Deutschland
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">Kontakt</h2>
              <p className="text-muted-foreground leading-relaxed">
                E-Mail: {email}
                <br />
                Website: {site}
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV</h2>
              <p className="text-muted-foreground leading-relaxed">
                Leandro Moreira<br />
                Anschrift wie oben
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">Haftung für Inhalte</h2>
              <p className="text-muted-foreground leading-relaxed">
                Die Inhalte dieser Website wurden mit größter Sorgfalt erstellt. 
                Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte 
                kann jedoch keine Gewähr übernommen werden.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">Haftung für Links</h2>
              <p className="text-muted-foreground leading-relaxed">
                Diese Website kann Links zu externen Webseiten Dritter enthalten. 
                Auf deren Inhalte besteht kein Einfluss. Für die Inhalte verlinkter 
                Seiten ist stets der jeweilige Anbieter verantwortlich.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">Urheberrecht</h2>
              <p className="text-muted-foreground leading-relaxed">
                Die auf dieser Website erstellten Inhalte und Werke unterliegen dem 
                deutschen Urheberrecht. Vervielfältigung, Bearbeitung, Verbreitung 
                und jede Art der Verwertung außerhalb der Grenzen des Urheberrechts 
                bedürfen der schriftlichen Zustimmung des jeweiligen Autors.
              </p>
            </section>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
