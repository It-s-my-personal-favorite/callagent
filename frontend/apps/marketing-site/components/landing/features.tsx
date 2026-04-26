import { Badge } from "@/components/ui/badge"
import { Clock, Headphones, HeartHandshake, MessageCircle, ShieldCheck, Volume2 } from "lucide-react"

const items = [
  {
    icon: Headphones,
    title: "Ein Mensch am Telefon",
    description:
      "Sie sprechen mit unseren Mitarbeitenden – keine Computerstimme, keine komplizierten Menüs.",
    highlight: true,
  },
  {
    icon: MessageCircle,
    title: "In Ihrem Tempo",
    description:
      "Wir erklären ruhig und wiederholen auf Wunsch. Sie müssen nichts vorbereiten und nichts auswendig wissen.",
    highlight: true,
  },
  {
    icon: HeartHandshake,
    title: "Respekt & Geduld",
    description:
      "Besonders wenn Lesen, Tippen oder komplexe Texte schwerfallen: Wir nehmen uns Zeit und hören zu.",
    highlight: false,
  },
  {
    icon: Volume2,
    title: "Verständlich erklärt",
    description:
      "Wir vermeiden Fachbegriffe. Wenn etwas unklar ist, sagen Sie es – wir formulieren es anders.",
    highlight: false,
  },
  {
    icon: Clock,
    title: "Pausen möglich",
    description:
      "Sie können jederzeit eine Pause verlangen oder später noch einmal anrufen.",
    highlight: false,
  },
  {
    icon: ShieldCheck,
    title: "Kein Druck",
    description:
      "Das Gespräch dient Ihrer Orientierung. Sie entscheiden, was Sie erzählen möchten – und was nicht.",
    highlight: false,
  },
] as const

export function Features() {
  return (
    <section id="angebot" className="py-10 sm:py-20 lg:py-28 bg-secondary/20 scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-7 sm:mb-12">
          <Badge variant="outline" className="mb-3 border-primary/50 text-foreground text-xs">
            Hilfe am Telefon
          </Badge>
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-balance">
            Was Sie erhalten, wenn Sie anrufen
          </h2>
          <p className="mt-3 text-sm sm:text-base text-muted-foreground">
            Die Nummer ist für alle gedacht, die lieber sprechen als schreiben – und für Menschen, die
            Unterstützung wegen Alter, Krankheit oder einer Behinderung brauchen.
          </p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-3 gap-2.5 sm:gap-5">
          {items.map((item) => (
            <div
              key={item.title}
              className={`group relative rounded-xl border p-3 sm:p-5 transition-all duration-300 hover:shadow-md ${
                item.highlight
                  ? "border-primary/50 bg-primary/5 hover:border-primary hover:bg-primary/10"
                  : "border-border/50 bg-card/50 hover:border-border hover:bg-card"
              }`}
            >
              {item.highlight && (
                <div className="absolute -top-2.5 right-3">
                  <Badge className="bg-primary text-primary-foreground text-xs px-2 py-0.5">Wichtig</Badge>
                </div>
              )}
              <div
                className={`flex h-9 w-9 sm:h-11 sm:w-11 items-center justify-center rounded-xl mb-3 ${
                  item.highlight
                    ? "bg-primary/20 border border-primary/30"
                    : "bg-secondary/50 border border-border/50 group-hover:bg-primary/10 group-hover:border-primary/20"
                }`}
              >
                <item.icon
                  className={`h-4 w-4 sm:h-5 sm:w-5 ${
                    item.highlight
                      ? "text-primary"
                      : "text-muted-foreground group-hover:text-primary"
                  } transition-colors`}
                />
              </div>
              <h3 className="text-xs sm:text-base font-semibold mb-1 leading-tight">{item.title}</h3>
              <p className="text-xs text-muted-foreground leading-relaxed hidden sm:block">{item.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
