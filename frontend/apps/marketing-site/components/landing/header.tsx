"use client"

import { useEffect, useRef, useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/theme-toggle"
import {
  Accessibility,
  Headphones,
  Home,
  ListChecks,
  GitBranch,
  HelpCircle,
  Menu,
  MessageCircleQuestion,
  PhoneCall,
  X,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { APP_NAME, getAppUrl, getHelpPhoneDisplay, getHelpPhoneTelHref } from "@/lib/site-config"

const navItems = [
  { label: "Start", href: "/", icon: Home, exact: true },
  { label: "Was Sie erhalten", href: "/#angebot", icon: ListChecks, exact: false },
  { label: "So geht's", href: "/#ablauf", icon: GitBranch, exact: false },
  { label: "Hilfe-Telefon", href: "/#hilfe", icon: HelpCircle, exact: false },
  { label: "Barrierefreiheit", href: "/#barrierefrei", icon: Accessibility, exact: false },
  { label: "Fragen", href: "/#faq", icon: MessageCircleQuestion, exact: false },
] as const

export function Header() {
  const menuRef = useRef<HTMLDialogElement>(null)
  const [scrolled, setScrolled] = useState(false)
  const pathname = usePathname()
  const helpTel = getHelpPhoneTelHref()
  const helpDisplay = getHelpPhoneDisplay()
  const appUrl = getAppUrl()

  const closeMenu = () => menuRef.current?.close()
  const openMenu = () => menuRef.current?.showModal()

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
            className="flex min-h-12 min-w-12 items-center gap-2 shrink-0 rounded-lg px-1 py-1 group transition-transform group-hover:scale-[1.01] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/15 border border-primary/30">
              <Headphones className="h-4 w-4 text-primary" aria-hidden />
            </div>
            <span className="font-bold text-lg tracking-tight">{APP_NAME}</span>
          </Link>

          <nav className="hidden lg:flex items-center gap-1" aria-label="Hauptnavigation">
            {navItems.map((item) => {
              const active = isActive(item)
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "relative inline-flex min-h-12 items-center px-3.5 py-2 text-sm font-medium rounded-lg transition-all duration-200",
                    active
                      ? "text-foreground"
                      : "text-foreground/75 hover:text-foreground hover:bg-secondary/60",
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

          <div className="hidden lg:flex items-center gap-3">
            <Button variant="default" className="min-h-12 gap-1.5 px-4" asChild>
              <a href={helpTel}>
                <PhoneCall className="h-3.5 w-3.5" aria-hidden />
                <span className="max-w-[10rem] truncate" title={helpDisplay}>
                  {helpDisplay}
                </span>
              </a>
            </Button>
            <ThemeToggle />
            <Button variant="outline" className="min-h-12 px-4" asChild>
              <a href={appUrl}>Zur App</a>
            </Button>
          </div>

          <div className="lg:hidden flex items-center gap-3">
            <Button variant="default" size="icon" className="shrink-0" asChild>
              <a href={helpTel} aria-label={`Hilfe anrufen: ${helpDisplay}`}>
                <PhoneCall className="h-4 w-4" />
              </a>
            </Button>
            <ThemeToggle />
            <Button type="button" variant="ghost" size="icon" aria-label="Menü öffnen" onClick={openMenu}>
              <Menu className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </div>

      <dialog
        ref={menuRef}
        aria-labelledby="mobile-nav-title"
        className={cn(
          "fixed inset-y-0 right-0 z-[60] m-0 h-full max-h-[100dvh] w-[min(20rem,100vw)] max-w-[100vw]",
          "translate-x-0 border-0 border-l border-border bg-background p-0 shadow-2xl outline-none",
          "[&::backdrop]:bg-black/50 [&::backdrop]:backdrop-blur-sm",
        )}
        onClick={(e) => {
          if (e.target === menuRef.current) closeMenu()
        }}
      >
        <div className="flex h-full flex-col" onClick={(e) => e.stopPropagation()}>
          <h2 id="mobile-nav-title" className="sr-only">
            Navigation
          </h2>
          <div className="flex items-center justify-between gap-2 border-b border-border px-4 py-4">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/15 border border-primary/30">
                <Headphones className="h-4 w-4 text-primary" aria-hidden />
              </div>
              <span className="font-semibold truncate">{APP_NAME}</span>
            </div>
            <Button type="button" variant="ghost" size="icon" aria-label="Menü schließen" onClick={closeMenu}>
              <X className="h-5 w-5" aria-hidden />
            </Button>
          </div>
          <nav className="flex-1 overflow-y-auto px-4 py-4" aria-label="Mobile Navigation">
            <ul className="space-y-1">
              {navItems.map((item) => {
                const active = isActive(item)
                return (
                  <li key={item.href}>
                    <Link
                      href={item.href}
                      onClick={closeMenu}
                      className={cn(
                        "flex min-h-12 items-center gap-3 px-3 py-3 text-sm font-medium rounded-lg transition-colors",
                        active
                          ? "bg-secondary text-foreground"
                          : "text-foreground/80 hover:text-foreground hover:bg-secondary/50",
                      )}
                    >
                      <item.icon className={cn("h-4 w-4 shrink-0", active ? "text-primary" : "")} />
                      {item.label}
                    </Link>
                  </li>
                )
              })}
            </ul>
          </nav>
          <div className="space-y-2 border-t border-border px-4 pb-6 pt-4">
            <Button className="w-full min-h-12 gap-2" asChild>
              <a href={helpTel} onClick={closeMenu}>
                <PhoneCall className="h-4 w-4" aria-hidden />
                Hilfe: {helpDisplay}
              </a>
            </Button>
            <Button variant="outline" className="w-full min-h-12" asChild>
              <a href={appUrl} onClick={closeMenu}>
                Zur App
              </a>
            </Button>
          </div>
        </div>
      </dialog>
    </header>
  )
}
