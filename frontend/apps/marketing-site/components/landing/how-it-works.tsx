import { Badge } from "@/components/ui/badge"
import { Ear, PhoneCall, Sparkles, ThumbsUp } from "lucide-react"

const steps = [
  {
    number: "01",
    icon: PhoneCall,
    title: "Sie rufen an",
    description:
      "Am besten von einem Telefon aus, an dem Sie sich wohlfühlen – Festnetz oder Mobil, wie Sie möchten.",
  },
  {
    number: "02",
    icon: Ear,
    title: "Wir hören zu",
    description:
      "Sie müssen nichts „Richtiges“ sagen. Erzählen Sie, was Sie brauchen oder was unklar ist.",
  },
  {
    number: "03",
    icon: Sparkles,
    title: "Wir erklären",
    description:
      "Wir fassen zusammen, was wir verstanden haben, und gehen auf Ihre Fragen ein – ohne Eile.",
  },
  {
    number: "04",
    icon: ThumbsUp,
    title: "Sie entscheiden",
    description:
      "Wenn etwas hilft, können Sie es sich notieren lassen oder später erneut anrufen. Kein Vertrag, kein Zwang.",
  },
]

export function HowItWorks() {
  return (
    <section id="ablauf" className="py-10 sm:py-20 lg:py-28 scroll-mt-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-12">
          <Badge variant="outline" className="mb-3 border-primary/50 text-foreground text-xs">
            Ablauf
          </Badge>
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-balance">
            So einfach geht&apos;s
          </h2>
          <p className="mt-3 text-sm sm:text-base text-muted-foreground">
            Vier Schritte – ohne Formulare und ohne Vorkenntnisse.
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
