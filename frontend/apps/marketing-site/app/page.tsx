import dynamic from "next/dynamic"
import { Header } from "@/components/landing/header"
import { Hero } from "@/components/landing/hero"
import { Footer } from "@/components/landing/footer"
import { CookieConsentLoader } from "@/components/landing/cookie-consent-loader"

const BelowFoldSections = dynamic(
  () =>
    import("@/components/landing/below-fold-sections").then((m) => ({
      default: m.BelowFoldSections,
    })),
  { loading: () => <div className="min-h-[32vh]" aria-hidden /> },
)

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-background" id="app">
      <Header />
      <main>
        <Hero />
        <BelowFoldSections />
      </main>
      <Footer />
      <CookieConsentLoader />
    </div>
  )
}
