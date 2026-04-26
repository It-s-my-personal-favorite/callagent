import { Header } from "@/components/landing/header"
import { Footer } from "@/components/landing/footer"
import Link from "next/link"
import { ArrowLeft } from "lucide-react"
import { Button } from "@/components/ui/button"
import type { Metadata } from "next"
import { getSupportEmail } from "@/lib/site-config"

export const metadata: Metadata = {
  title: "Datenschutz – CallAgent",
  description: "Datenschutzerklärung von CallAgent",
}

export default function DatenschutzPage() {
  const privacyEmail = getSupportEmail()
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

          <h1 className="text-4xl font-bold tracking-tight mb-12">Datenschutzerklärung</h1>

          <div className="space-y-8">
            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">1. Verantwortlicher</h2>
              <p className="text-muted-foreground leading-relaxed">
                Verantwortlich für die Datenverarbeitung auf dieser Website ist:<br /><br />
                CallAgent<br />
                Leandro Moreira<br />
                Musterstraße 1<br />
                12345 Musterstadt<br />
                Deutschland<br /><br />
                E-Mail: {privacyEmail}
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">2. Allgemeine Hinweise zur Datenverarbeitung</h2>
              <p className="text-muted-foreground leading-relaxed">
                Der Schutz personenbezogener Daten hat hohe Priorität. Daten werden nur verarbeitet, 
                soweit dies zur Bereitstellung einer funktionsfähigen Website sowie unserer Inhalte 
                und Leistungen erforderlich ist. Die Verarbeitung erfolgt auf Basis der DSGVO und 
                des BDSG.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">3. Software und personenbezogene Inhalte</h2>
              <div className="text-muted-foreground leading-relaxed space-y-4">
                <p>
                  <strong className="text-foreground">Anwendung:</strong>
                  <br />
                  In der produktiven CallAgent-Installation (Admin-App und Backend) können
                  personenbezogene Daten aus Telefonie und Gesprächen verarbeitet werden, etwa
                  Rufnummern, Kundenhistorie, Notizen, Transkripte, Aufnahmen und Bewertungen. Umfang
                  und Rechtsgrundlagen ergeben sich aus Ihrem Einsatzzweck, dem Mitarbeiter- oder
                  Kundenverhältnis sowie ggf. erteilten Einwilligungen.
                </p>
                <p>
                  <strong className="text-foreground">Diese Website (Landingpage):</strong>
                  <br />
                  Die öffentliche Website dient der Information. Es besteht kein Muss zur
                  Registrierung, um Texte einzusehen. Sofern Sie per E-Mail oder Telefon Kontakt
                  aufnehmen, verarbeiten wir die dabei mitgeteilten Daten zur Bearbeitung der Anfrage.
                </p>
              </div>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">4. Erhebung von Zugriffsdaten und Server-Logfiles</h2>
              <p className="text-muted-foreground leading-relaxed">
                Beim Aufruf der Website werden technisch notwendige Daten (z. B. Browsertyp, 
                Betriebssystem, Referrer, Uhrzeit, IP-Adresse) automatisiert in Server-Logfiles 
                gespeichert. Diese Verarbeitung erfolgt zur Gewährleistung von Sicherheit, 
                Stabilität und Fehleranalyse. Die Speicherdauer beträgt maximal 7 Tage.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">5. Verwendung von Cookies</h2>
              <p className="text-muted-foreground leading-relaxed">
                Auf dieser Website kommen grundsätzlich nur unbedingt erforderliche, 
                funktionale Cookies zum Einsatz. Diese dienen der Sicherheit und der Umsetzung 
                gewisser Voreinstellungen. Die Nutzung von Cookies ist für die Erbringung unserer 
                Dienstleistungen zwingend erforderlich (Art. 6 (1) b DSGVO).<br /><br />
                <strong className="text-foreground">Hinweis:</strong> Die Admin-Applikation selbst
                kann weitere, für den Betrieb nötige Cookies/Speicher (z. B. Sitzung, Theme) setzen
                – abhängig von Ihrer technischen Konfiguration.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">6. Rechtsgrundlagen der Verarbeitung</h2>
              <p className="text-muted-foreground leading-relaxed">
                Die Verarbeitung erfolgt auf Basis von:<br /><br />
                • Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)<br />
                • Art. 6 Abs. 1 lit. b DSGVO (Vertrag)<br />
                • Art. 6 Abs. 1 lit. c DSGVO (rechtliche Pflicht)<br />
                • Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse)
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">7. Speicherdauer</h2>
              <p className="text-muted-foreground leading-relaxed">
                Personenbezogene Daten werden nur so lange gespeichert, wie es für den jeweiligen 
                Zweck erforderlich ist oder gesetzliche Aufbewahrungspflichten bestehen.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">8. Betroffenenrechte</h2>
              <p className="text-muted-foreground leading-relaxed">
                Betroffene Personen haben das Recht auf:<br /><br />
                • Auskunft (Art. 15 DSGVO)<br />
                • Berichtigung (Art. 16 DSGVO)<br />
                • Löschung (Art. 17 DSGVO)<br />
                • Einschränkung der Verarbeitung (Art. 18 DSGVO)<br />
                • Datenübertragbarkeit (Art. 20 DSGVO)<br />
                • Widerspruch (Art. 21 DSGVO)<br /><br />
                Zudem besteht ein Beschwerderecht bei einer Datenschutzaufsichtsbehörde.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">9. Datensicherheit</h2>
              <p className="text-muted-foreground leading-relaxed">
                Es werden technische und organisatorische Sicherheitsmaßnahmen eingesetzt, 
                um Daten gegen Verlust, Manipulation und unberechtigten Zugriff zu schützen. 
                Die Übertragung erfolgt verschlüsselt (TLS/SSL) soweit von der Infrastruktur
                unterstützt. Speicherort und Backup richten sich nach Ihrem bzw. unserem Hosting.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">10. Auftragsverarbeitung (AVV)</h2>
              <p className="text-muted-foreground leading-relaxed">
                Wir bieten unseren Unternehmenskunden den Abschluss eines Vertrages zur 
                Auftragsverarbeitung (AVV) gemäß Art. 28 DSGVO an. Kontaktieren Sie uns 
                für weitere Informationen unter {privacyEmail}.
              </p>
            </section>

            <section className="rounded-2xl border border-border/50 bg-card/50 p-8">
              <h2 className="text-xl font-semibold mb-4">11. Aktualisierung dieser Datenschutzerklärung</h2>
              <p className="text-muted-foreground leading-relaxed">
                Diese Datenschutzerklärung kann angepasst werden, wenn sich rechtliche 
                Anforderungen oder technische Prozesse ändern.<br /><br />
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
