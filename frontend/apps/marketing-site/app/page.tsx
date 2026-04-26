import { Header } from "@/components/landing/header"
import { Hero } from "@/components/landing/hero"
import { HelpHotline } from "@/components/landing/help-hotline"
import { Features } from "@/components/landing/features"
import { HowItWorks } from "@/components/landing/how-it-works"
import { AccessibilityLanding } from "@/components/landing/accessibility-landing"
import { FAQ } from "@/components/landing/faq"
import { Footer } from "@/components/landing/footer"
import { CookieConsent } from "@/components/landing/cookie-consent"

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-background" id="app">
      <Header />
      <main>
        <Hero />
        <HelpHotline />
        <Features />
        <HowItWorks />
        <AccessibilityLanding />
        <FAQ />
      </main>
      <Footer />
      <CookieConsent />
    </div>
  )
}
