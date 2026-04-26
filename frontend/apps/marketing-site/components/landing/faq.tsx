import { Badge } from "@/components/ui/badge"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"
import { getHelpPhoneDisplay, getHelpPhoneTelHref, getSupportEmail } from "@/lib/site-config"

const faqStatic = [
  {
    question: "Was kostet der Anruf?",
    answer:
      "Die Hotline ist für Sie kostenfrei bestimmt. Bei Anrufen vom Handy kann Ihr Mobilfunkanbieter trotzdem Gebühren erheben – das liegt außerhalb unseres Einflusses.",
  },
  {
    question: "Muss ich etwas vorbereiten oder ausfüllen?",
    answer:
      "Nein. Sie brauchen keine Nummern, Codes oder Formulare. Rufen Sie an, wenn Sie möchten, und sagen Sie uns in Ruhe, worum es geht.",
  },
  {
    question: "Ich höre oder spreche schlecht – geht das trotzdem?",
    answer: "",
  },
  {
    question: "Wie lange dauert ein Gespräch?",
    answer:
      "So lange, wie Sie es brauchen. Sie können jederzeit eine Pause machen oder auflegen und später erneut anrufen.",
  },
  {
    question: "Ersetzt die Hotline einen Arzt, die Polizei oder den Notdienst?",
    answer:
      "Nein. Bei medizinischen oder polizeilichen Notfällen wählen Sie bitte 112 bzw. 110. Wir ersetzen keine professionelle Beratung in Krisenfällen.",
  },
  {
    question: "Wer darf anrufen?",
    answer: "",
  },
] as const

export function FAQ() {
  const helpTel = getHelpPhoneTelHref()
  const helpDisplay = getHelpPhoneDisplay()
  const email = getSupportEmail()

  const faqs = faqStatic.map((f) => {
    if (f.question.startsWith("Ich höre oder spreche")) {
      return {
        ...f,
        answer: `Ja. Sagen Sie uns, was für Sie hilft – z. B. langsamer sprechen, Wiederholungen oder lautere Stimme. Wenn ein Schriftstück der Ausgangspunkt ist, können wir es gemeinsam Schritt für Schritt durchgehen. Bei Bedarf erreichen Sie uns auch schriftlich unter ${email}.`,
      }
    }
    if (f.question.startsWith("Wer darf anrufen")) {
      return {
        ...f,
        answer: `Jede Person, die Unterstützung beim Verstehen oder bei alltäglichen Fragen braucht – besonders ältere Menschen und Menschen mit Einschränkungen. Die Nummer lautet `,
      }
    }
    return f
  })

  return (
    <section id="faq" className="py-10 sm:py-20 lg:py-28 bg-secondary/20 scroll-mt-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-7 sm:mb-12">
          <Badge variant="outline" className="mb-3 border-primary/50 text-foreground text-xs">
            FAQ
          </Badge>
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-balance">
            Häufige Fragen
          </h2>
          <p className="mt-3 text-sm sm:text-base text-muted-foreground">
            Antworten rund um die Hilfe-Hotline – kurz und in Alltagssprache.
          </p>
        </div>

        <Accordion type="single" collapsible className="space-y-2 sm:space-y-3">
          {faqs.map((faq, index) => (
            <AccordionItem
              key={index}
              value={`item-${index}`}
              className="rounded-xl border border-border/50 bg-card/50 px-3 sm:px-6 data-[state=open]:border-primary/50 data-[state=open]:bg-primary/5 transition-all"
            >
              <AccordionTrigger className="min-h-12 items-center text-left hover:no-underline py-3.5 sm:min-h-0 sm:py-5 text-sm sm:text-base">
                <span className="font-semibold pr-4">{faq.question}</span>
              </AccordionTrigger>
              <AccordionContent className="text-xs sm:text-sm text-muted-foreground pb-3.5 sm:pb-5 leading-relaxed">
                {faq.question.startsWith("Wer darf anrufen") ? (
                  <>
                    {faq.answer}
                    <a href={helpTel} className="text-primary font-medium hover:underline">
                      {helpDisplay}
                    </a>
                    .
                  </>
                ) : (
                  faq.answer
                )}
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>

        <div className="mt-8 text-center">
          <p className="text-sm text-muted-foreground">
            Rufen Sie uns an:{" "}
            <a href={helpTel} className="text-primary hover:underline font-medium">
              {helpDisplay}
            </a>
          </p>
        </div>
      </div>
    </section>
  )
}
