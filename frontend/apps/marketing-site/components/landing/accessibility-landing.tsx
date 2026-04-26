import { Badge } from "@/components/ui/badge"
import { Contrast, Headphones, Keyboard, MousePointer2 } from "lucide-react"

const items = [
  {
    icon: Contrast,
    title: "Lesbare Seite",
    text: "Diese Website nutzt klare Schrift und ausreichend Kontrast. Wichtige Bereiche sind mit Überschriften gekennzeichnet.",
  },
  {
    icon: Keyboard,
    title: "Bedienung",
    text: "Sie können die Seite größtenteils mit Tastatur oder Maus bedienen. Die Telefonnummer ist als Link zum Wählen auf dem Handy gesetzt.",
  },
  {
    icon: Headphones,
    title: "Hilfe ohne Bildschirm",
    text: "Am wichtigsten ist die Hotline: Wenn Lesen mühsam ist, reicht oft ein Anruf – wir erklären alles mündlich.",
  },
  {
    icon: MousePointer2,
    title: "Orientierung",
    text: "Die Reihenfolge auf der Seite entspricht der üblichen Leserichtung. Unten finden Sie Impressum und Datenschutz.",
  },
]

export function AccessibilityLanding() {
  return (
    <section id="barrierefrei" className="py-10 sm:py-16 bg-secondary/20 scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-7 sm:mb-10">
          <Badge variant="outline" className="mb-3 border-primary/50 text-foreground text-xs">
            Barrierefreiheit
          </Badge>
          <h2 className="text-2xl sm:text-3xl font-bold tracking-tight">Damit Sie sich zurechtfinden</h2>
          <p className="mt-2 text-sm sm:text-base text-muted-foreground">
            Die Hotline ist unser wichtigstes Angebot für alle, denen lange Texte oder Klicks zu viel
            werden. Zusätzlich halten wir diese Seite möglichst klar und ruhig.
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
