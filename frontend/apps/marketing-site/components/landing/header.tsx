"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Sheet, SheetContent, SheetTrigger, SheetTitle } from "@/components/ui/sheet"
import { ThemeToggle } from "@/components/theme-toggle"
import { Headphones, Home, ListChecks, GitBranch, HelpCircle, Menu, MessageCircleQuestion, PhoneCall } from "lucide-react"
import { cn } from "@/lib/utils"
import { APP_NAME, getAppUrl, getHelpPhoneDisplay, getHelpPhoneTelHref } from "@/lib/site-config"

const navItems = [
  { label: "Start", href: "/", icon: Home, exact: true },
  { label: "Funktionen", href: "/#funktionen", icon: ListChecks, exact: false },
  { label: "Ablauf", href: "/#ablauf", icon: GitBranch, exact: false },
  { label: "Hilfe & Barriere", href: "/#hilfe", icon: HelpCircle, exact: false },
  { label: "Fragen", href: "/#faq", icon: MessageCircleQuestion, exact: false },
] as const

export function Header() {
  const [isOpen, setIsOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)
  const pathname = usePathname()
  const helpTel = getHelpPhoneTelHref()
  const helpDisplay = getHelpPhoneDisplay()
  const appUrl = getAppUrl()

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20)
    window.addEventListener("scroll", handleScroll, { passive: true })
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const isActive = (item: (typeof navItems)[number]) => {
    if (item.exact) return pathname === item.href
    if (item.href.startsWith("/#") && pathname === "/") return false
    return pathname === item.href || pathname.startsWith(item.href + "/")
  }

  return (
    <header
      className={cn(
        "fixed top-0 left-0 right-0 z-50 transition-all duration-300",
        scrolled
          ? "bg-background/90 backdrop-blur-xl border-b border-border/60 shadow-sm"
          : "bg-background/60 backdrop-blur-md border-b border-transparent",
      )}
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-14 sm:h-16 items-center justify-between gap-3 sm:gap-4">
          <Link
            href="/"
            className="flex items-center gap-2 shrink-0 group transition-transform group-hover:scale-[1.01]"
          >
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/15 border border-primary/30">
              <Headphones className="h-4 w-4 text-primary" aria-hidden />
            </div>
            <span className="font-bold text-lg tracking-tight">{APP_NAME}</span>
          </Link>

          <nav className="hidden lg:flex items-center gap-0.5" aria-label="Hauptnavigation">
            {navItems.map((item) => {
              const active = isActive(item)
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "relative px-3.5 py-2 text-sm font-medium rounded-lg transition-all duration-200",
                    active
                      ? "text-foreground"
                      : "text-muted-foreground hover:text-foreground hover:bg-secondary/60",
                  )}
                >
                  {active && <span className="absolute inset-0 rounded-lg bg-secondary/80" />}
                  <span className="relative">{item.label}</span>
                  {active && (
                    <span className="absolute bottom-0.5 left-1/2 -translate-x-1/2 w-4 h-0.5 rounded-full bg-primary" />
                  )}
                </Link>
              )
            })}
          </nav>

          <div className="hidden lg:flex items-center gap-2">
            <Button variant="default" size="sm" className="gap-1.5" asChild>
              <a href={helpTel}>
                <PhoneCall className="h-3.5 w-3.5" aria-hidden />
                <span className="max-w-[10rem] truncate" title={helpDisplay}>
                  {helpDisplay}
                </span>
              </a>
            </Button>
            <ThemeToggle />
            <Button variant="outline" size="sm" asChild>
              <a href={appUrl}>Zur App</a>
            </Button>
          </div>

          <div className="lg:hidden flex items-center gap-0.5 sm:gap-1">
            <Button variant="default" size="icon" className="shrink-0" asChild>
              <a href={helpTel} aria-label={`Hilfe anrufen: ${helpDisplay}`}>
                <PhoneCall className="h-4 w-4" />
              </a>
            </Button>
            <ThemeToggle />
            <Sheet open={isOpen} onOpenChange={setIsOpen}>
              <SheetTrigger asChild>
                <Button variant="ghost" size="icon" aria-label="Menü öffnen">
                  <Menu className="h-5 w-5" />
                </Button>
              </SheetTrigger>
              <SheetContent side="right" className="w-80 bg-background border-border p-0">
                <SheetTitle className="sr-only">Navigation</SheetTitle>
                <div className="flex flex-col h-full">
                  <div className="flex items-center gap-2.5 px-6 py-5 border-b border-border">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/15 border border-primary/30">
                      <Headphones className="h-4 w-4 text-primary" />
                    </div>
                    <span className="font-semibold">{APP_NAME}</span>
                  </div>
                  <nav className="flex-1 px-4 py-4" aria-label="Mobile Navigation">
                    <ul className="space-y-1">
                      {navItems.map((item) => {
                        const active = isActive(item)
                        return (
                          <li key={item.href}>
                            <Link
                              href={item.href}
                              onClick={() => setIsOpen(false)}
                              className={cn(
                                "flex items-center gap-3 px-3 py-3 text-sm font-medium rounded-lg transition-colors",
                                active
                                  ? "bg-secondary text-foreground"
                                  : "text-muted-foreground hover:text-foreground hover:bg-secondary/50",
                              )}
                            >
                              <item.icon className={cn("h-4 w-4", active ? "text-primary" : "")} />
                              {item.label}
                            </Link>
                          </li>
                        )
                      })}
                    </ul>
                  </nav>
                  <div className="px-4 pb-6 space-y-2 border-t border-border pt-4">
                    <Button className="w-full gap-2" asChild>
                      <a href={helpTel} onClick={() => setIsOpen(false)}>
                        <PhoneCall className="h-4 w-4" />
                        Hilfe: {helpDisplay}
                      </a>
                    </Button>
                    <Button variant="outline" className="w-full" asChild>
                      <a href={appUrl} onClick={() => setIsOpen(false)}>
                        Zur App
                      </a>
                    </Button>
                  </div>
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </div>
      </div>
    </header>
  )
}
