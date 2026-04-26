import { AccessibilityLanding } from "@/components/landing/accessibility-landing"
import { FAQ } from "@/components/landing/faq"
import { Features } from "@/components/landing/features"
import { HelpHotline } from "@/components/landing/help-hotline"
import { HowItWorks } from "@/components/landing/how-it-works"

/** Alles unter dem Hero in einem Chunk für kleineres initiales JS (Lighthouse / TBT). */
export function BelowFoldSections() {
  return (
    <>
      <HelpHotline />
      <Features />
      <HowItWorks />
      <AccessibilityLanding />
      <FAQ />
    </>
  )
}
