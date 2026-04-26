export const THEME_COOKIE = "callagent_theme" as const

export type ThemeMode = "light" | "dark"

const bootScript = `(function(){try{var m=document.cookie.match(/(?:^|; )callagent_theme=(light|dark)(?:;|$)/);var t=m?m[1]:null;if(!t){t=window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light";document.cookie="callagent_theme="+t+"; Max-Age=31536000; Path=/; SameSite=Lax"}try{localStorage.setItem("theme",t)}catch(e){}var r=document.documentElement;if(t==="dark"){r.classList.add("dark")}else{r.classList.remove("dark")}}catch(e){}})();`

export const THEME_BOOT_SCRIPT = bootScript

export function writeThemeCookie(theme: ThemeMode): void {
  if (typeof document === "undefined") return
  const secure = typeof location !== "undefined" && location.protocol === "https:" ? "; Secure" : ""
  document.cookie = `${THEME_COOKIE}=${theme}; Max-Age=31536000; Path=/; SameSite=Lax${secure}`
}
