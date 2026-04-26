"use client"

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
    question: "Was genau ist CallAgent?",
    answer:
      "CallAgent ist die Admin-Oberfläche für eingehende Anrufe: Sie sehen Live- und Verlaufs-Calls, Kundenkontext, Transkripte, Aufnahmen, können moderieren, notieren und Ihre Sprach-API/Backend-Verbindung prüfen.",
  },
  {
    question: "Brauche ich dafür ein eigenes Telefonie-Backend?",
    answer:
      "Ja, CallAgent arbeitet mit einem angebundenen Server (z. B. FastAPI) und Ihrer Konfiguration für Voice/Provider. Die Landingpage ersetzt keine Telefonanlage, sondern beschreibt die Steuer- und Auswertungs-App.",
  },
  {
    question: "Wo finde ich Hilfe, wenn lesen oder Klicken schwerfällt?",
    answer: "", // filled below
  },
  {
    question: "Sind meine Gespräche und Nummern geschützt?",
    answer:
      "Zugriff, Rollen und Hosting regeln Sie mit Ihrem IT-Betrieb. In der App können Sie z. B. sperren und Nachweise exportieren. Technische und organisatorische Maßnahmen hängen von Ihrer Installation ab.",
  },
  {
    question: "Gibt es Mobile oder nur Desktop?",
    answer:
      "Die Admin-Oberfläche ist für moderne Browser ausgelegt; die Flutter-App kann je nach Build auch mobil laufen. Wichtige Schritte sind touch-freundlich gestaltet, wo sinnvoll.",
  },
  {
    question: "Wer ist die Hotline-Nummer für?",
    answer: "",
  },
] as const

export function FAQ() {
  const helpTel = getHelpPhoneTelHref()
  const helpDisplay = getHelpPhoneDisplay()
  const email = getSupportEmail()

  const faqs = faqStatic.map((f) => {
    if (f.question.startsWith("Wo finde ich Hilfe")) {
      return {
        ...f,
        answer: `Unter ${helpDisplay} erreichen Sie unsere Hilfe – wir nehmen uns Zeit, erklären einfach und passen uns Ihren Bedürfnissen an. Oder per E-Mail: ${email}.`,
      }
    }
    if (f.question.startsWith("Wer ist die Hotline")) {
      return {
        ...f,
        answer: `Speziell für Seniorinnen und Senioren, für Menschen mit Einschränkungen und für alle, die lieber anrufen als Formulare ausfüllen. Die Nummer wählen Sie direkt: `,
      }
    }
    return f
  })

  return (
    <section id="faq" className="py-10 sm:py-20 lg:py-28 bg-secondary/20 scroll-mt-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-7 sm:mb-12">
          <Badge variant="outline" className="mb-3 border-primary/50 text-primary text-xs">
            FAQ
          </Badge>
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-balance">
            Häufig gestellte Fragen
          </h2>
          <p className="mt-3 text-sm sm:text-base text-muted-foreground">
            Kurz beantwortet, was Unternehmen und Hilfesuchende wissen wollen.
          </p>
        </div>

        <Accordion type="single" collapsible className="space-y-2 sm:space-y-3">
          {faqs.map((faq, index) => (
            <AccordionItem
              key={index}
              value={`item-${index}`}
              className="rounded-xl border border-border/50 bg-card/50 px-3 sm:px-6 data-[state=open]:border-primary/50 data-[state=open]:bg-primary/5 transition-all"
            >
              <AccordionTrigger className="text-left hover:no-underline py-3.5 sm:py-5 text-sm sm:text-base">
                <span className="font-semibold pr-4">{faq.question}</span>
              </AccordionTrigger>
              <AccordionContent className="text-xs sm:text-sm text-muted-foreground pb-3.5 sm:pb-5 leading-relaxed">
                {faq.question.startsWith("Wer ist die Hotline") ? (
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
            Rufen Sie an:{" "}
            <a href={helpTel} className="text-primary hover:underline font-medium">
              {helpDisplay}
            </a>
          </p>
        </div>
      </div>
    </section>
  )
}
