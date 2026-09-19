# iPhone-First PWA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing Football Agent web game an installable, simple, iPhone-first PWA while preserving its Python simulation, game flow, routes, and editorial artwork.

**Architecture:** Keep the Python engine, FastAPI service, Server Components, Server Actions, session cookies, and saves unchanged. Add install metadata and static icons, then reshape the existing responsive shell and shared primitives below `md`; individual screens only receive mechanical mobile-density fixes where shared components cannot cover them.

**Tech Stack:** Next.js 15 App Router, React 19, TypeScript, Tailwind CSS 4, Vitest/Testing Library, Playwright, FastAPI/Python, macOS `qlmanage` and `sips` for checked-in PNG icons.

**Spec:** `docs/superpowers/specs/2026-09-19-iphone-first-pwa-design.md`

## Global Constraints

- The Python simulation, FastAPI service, DTOs, save format, and game rules stay authoritative and unchanged.
- The existing Next.js application remains the only frontend; add no SwiftUI, React Native, wrapper, service worker, push notification, or background-sync implementation.
- Preserve every playable route and the existing office, scouting, career, headquarters, investment, and agency artwork.
- Keep desktop behavior usable; the new shell and component rules apply primarily below `md`.
- Use a four-item phone tab bar containing Office, Clients, Scouting, and More; tabs perform navigation only.
- Keep decision review and week advancement in a separate action toolbar above the tab bar.
- All important phone controls have at least a 44 by 44 CSS-pixel target and all fixed chrome respects `env(safe-area-inset-*)`.
- The installed PWA launches in `standalone`, portrait-primary mode but does not claim offline gameplay.
- Preserve focus traps, Escape handling, backdrop dismissal, focus restoration, visible focus, and reduced-motion behavior.

## Review Focus

- An iPhone with a nonzero top and bottom safe area must show every status, action, tab, toast, and sheet control without clipping; Task 3 adds bounding-box and overlap assertions at 390 by 844.
- A player on a secondary route must see More as the active tab and be able to reach all eight secondary destinations; Task 2 tests child-route state and every More-sheet link.
- Zero or multiple open decisions must not change the action toolbar height or hide week advancement; Tasks 2 and 3 test both accessible labels and fixed-chrome geometry.
- A sheet taller than the available viewport must scroll internally without nesting the page scroll or hiding its close control; Tasks 2 and 3 test dialog semantics and viewport bounds.
- Browsing without installing must retain the same game, while Home Screen launch must use standalone metadata and valid icons; Task 1 tests the manifest and root metadata and validates icon dimensions.

---

### Task 1: Installable PWA metadata and icons

**Files:**
- Create: `web/app/manifest.ts`
- Create: `web/app/manifest.test.ts`
- Create: `web/public/icons/football-agent.svg`
- Create: `web/public/icons/icon-192.png`
- Create: `web/public/icons/icon-512.png`
- Create: `web/public/icons/apple-touch-icon.png`
- Modify: `web/app/layout.tsx:1-30`

**Interfaces:**
- Consumes: Next.js `Metadata`, `MetadataRoute`, and `Viewport` types.
- Produces: `manifest(): MetadataRoute.Manifest`, `/manifest.webmanifest`, three static icon URLs, and exported `metadata` and `viewport` values used by Next.js document rendering.

- [ ] **Step 1: Write the failing manifest test**

```tsx
import { describe, expect, it } from "vitest";

import manifest from "./manifest";
import { metadata, viewport } from "./layout";

describe("iPhone PWA metadata", () => {
  it("launches as a portrait standalone app with install icons", () => {
    const value = manifest();
    expect(value).toMatchObject({
      id: "/",
      start_url: "/",
      display: "standalone",
      orientation: "portrait-primary",
      background_color: "#101b17",
      theme_color: "#17251f",
    });
    expect(value.icons).toEqual([
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any maskable" },
    ]);
    expect(metadata.manifest).toBe("/manifest.webmanifest");
    expect(metadata.appleWebApp).toMatchObject({ capable: true, statusBarStyle: "black-translucent" });
    expect(viewport).toMatchObject({ width: "device-width", initialScale: 1, viewportFit: "cover" });
  });
});
```

- [ ] **Step 2: Run the test and verify the missing manifest fails**

Run: `cd web && npm test -- --run app/manifest.test.ts`

Expected: FAIL because `web/app/manifest.ts` does not exist and `viewport` is not exported.

- [ ] **Step 3: Add the manifest and root iPhone metadata**

```tsx
// web/app/manifest.ts
import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/",
    name: "Football Agent",
    short_name: "Football Agent",
    description: "Scout talent, represent clients, and build a football agency.",
    start_url: "/",
    display: "standalone",
    orientation: "portrait-primary",
    background_color: "#101b17",
    theme_color: "#17251f",
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any maskable" },
    ],
  };
}
```

```tsx
// additions in web/app/layout.tsx
import type { Metadata, Viewport } from "next";

export const metadata: Metadata = {
  title: "Football Agent",
  description: "Scout on incomplete information, sign clients, take your cut.",
  applicationName: "Football Agent",
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Football Agent",
  },
  icons: { apple: "/icons/apple-touch-icon.png" },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  colorScheme: "dark",
  themeColor: "#17251f",
};
```

- [ ] **Step 4: Add the source emblem and render the three PNGs**

Create `web/public/icons/football-agent.svg` as a square forest-green icon with a warm-ivory shield, center football, and generous 12.5% maskable padding:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" rx="224" fill="#101b17"/>
  <path d="M512 142 790 246v223c0 188-111 331-278 413C345 800 234 657 234 469V246Z" fill="#f0eadb" stroke="#c8b77c" stroke-width="34"/>
  <circle cx="512" cy="493" r="177" fill="#203128" stroke="#c8b77c" stroke-width="22"/>
  <path d="m512 397 84 61-32 99H460l-32-99Zm0-81v81m-168 90 84-29m252 29-84-29M408 656l52-99m156 99-52-99" fill="none" stroke="#f0eadb" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

Render and resize without adding a package:

```bash
mkdir -p /tmp/football-agent-icons
qlmanage -t -s 1024 -o /tmp/football-agent-icons web/public/icons/football-agent.svg
sips -z 192 192 /tmp/football-agent-icons/football-agent.svg.png --out web/public/icons/icon-192.png
sips -z 512 512 /tmp/football-agent-icons/football-agent.svg.png --out web/public/icons/icon-512.png
sips -z 180 180 /tmp/football-agent-icons/football-agent.svg.png --out web/public/icons/apple-touch-icon.png
```

- [ ] **Step 5: Verify metadata and icon dimensions**

Run: `cd web && npm test -- --run app/manifest.test.ts`

Expected: PASS.

Run: `sips -g pixelWidth -g pixelHeight web/public/icons/icon-192.png web/public/icons/icon-512.png web/public/icons/apple-touch-icon.png`

Expected: dimensions are 192×192, 512×512, and 180×180 respectively.

- [ ] **Step 6: Commit installability**

```bash
git add web/app/layout.tsx web/app/manifest.ts web/app/manifest.test.ts web/public/icons
git commit -m "feat: make game installable on iPhone"
```

---

### Task 2: Phone navigation, status, actions, and sheets

**Files:**
- Create: `web/components/shell/nav-rail.test.tsx`
- Create: `web/components/dialog.test.tsx`
- Modify: `web/components/shell/nav-rail.tsx:1-137`
- Modify: `web/components/shell/status-bar.tsx:1-111`
- Modify: `web/components/continue-button.tsx:1-90`
- Modify: `web/components/dialog.tsx:15-96`
- Modify: `web/components/toaster.tsx:49-70`
- Modify: `web/components/ui.tsx:296-310`
- Modify: `web/app/(game)/layout.tsx:53-82`

**Interfaces:**
- Consumes: existing `NAV`, `Dialog`, `ContinueButton`, `StatusBar`, `buttonClass`, `GameState`, decision count map, and current pathname.
- Produces: exported `PHONE_TABS` and `MORE_NAV` route lists, a four-tab phone navigation landmark, a bottom-sheet More menu, and nonoverlapping status/action chrome. No API signatures change.

- [ ] **Step 1: Add failing navigation and dialog tests**

```tsx
// web/components/shell/nav-rail.test.tsx
import { fireEvent, render, screen, within } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { ReactNode } from "react";

import { NavStrip } from "./nav-rail";

let pathname = "/";
vi.mock("next/navigation", () => ({ usePathname: () => pathname }));
vi.mock("next/link", () => ({
  default: ({ href, children, ...props }: { href: string; children: ReactNode }) => <a href={href} {...props}>{children}</a>,
}));

beforeEach(() => { pathname = "/"; });

describe("phone navigation", () => {
  it("keeps the three primary destinations and More visible", () => {
    render(<NavStrip counts={{ "/clients": 2 }} />);
    const nav = screen.getByRole("navigation", { name: "Sections" });
    expect(within(nav).getAllByRole("link")).toHaveLength(3);
    expect(within(nav).getByRole("link", { name: "Office" })).toHaveAttribute("href", "/");
    expect(within(nav).getByRole("link", { name: /Clients/ })).toHaveAttribute("href", "/clients");
    expect(within(nav).getByRole("link", { name: "Scouting" })).toHaveAttribute("href", "/scouting");
    expect(within(nav).getByRole("button", { name: "More" })).toBeVisible();
  });

  it("marks More active on child routes and exposes every secondary destination", () => {
    pathname = "/headquarters";
    render(<NavStrip counts={{}} />);
    const more = screen.getByRole("button", { name: "More" });
    expect(more).toHaveAttribute("aria-current", "page");
    fireEvent.click(more);
    const sheet = screen.getByRole("dialog", { name: "Around the agency" });
    for (const [name, href] of [["Agency", "/agency"], ["Finances", "/finances"], ["World", "/world"], ["Market", "/market"], ["Careers", "/careers"], ["Stocks", "/investments"], ["Headquarters", "/headquarters"], ["Season review", "/season-review"]]) {
      expect(within(sheet).getByRole("link", { name })).toHaveAttribute("href", href);
    }
  });
});
```

```tsx
// web/components/dialog.test.tsx
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { Dialog } from "./dialog";

describe("Dialog", () => {
  it("retains modal semantics and a close target in the phone sheet", () => {
    const close = vi.fn();
    render(<Dialog open onClose={close} title="Review"><button>Decision</button></Dialog>);
    expect(screen.getByRole("dialog", { name: "Review" })).toHaveAttribute("aria-modal", "true");
    fireEvent.click(screen.getByRole("button", { name: "Close" }));
    expect(close).toHaveBeenCalledOnce();
  });
});
```

- [ ] **Step 2: Run the tests and verify the old route set fails**

Run: `cd web && npm test -- --run components/shell/nav-rail.test.tsx components/dialog.test.tsx`

Expected: navigation test FAIL because Market is currently a primary tab, Headquarters is absent, and More has no active route state; dialog semantics test remains green as a regression guard.

- [ ] **Step 3: Implement the fixed four-tab navigation and More sheet**

Keep `NAV` unchanged for desktop. Add these phone collections and render from them:

```tsx
export const PHONE_TABS = NAV.filter(({ href }) => ["/", "/clients", "/scouting"].includes(href));
export const MORE_NAV = [
  NAV.find(({ href }) => href === "/agency")!,
  NAV.find(({ href }) => href === "/finances")!,
  NAV.find(({ href }) => href === "/world")!,
  NAV.find(({ href }) => href === "/market")!,
  NAV.find(({ href }) => href === "/careers")!,
  NAV.find(({ href }) => href === "/investments")!,
  { href: "/headquarters", label: "Headquarters", key: "", Icon: Building2 },
  { href: "/season-review", label: "Season review", key: "", Icon: Trophy },
] as const;

const moreActive = MORE_NAV.some(({ href }) => pathname === href || pathname.startsWith(`${href}/`));
```

Render the phone navigation and sheet with this structure; keep the existing
desktop `NavRail` unchanged:

```tsx
<nav
  data-phone-chrome
  aria-label="Sections"
  className="fixed inset-x-0 bottom-0 z-30 grid h-[calc(64px+env(safe-area-inset-bottom))] grid-cols-4 border-t border-line bg-panel/95 px-[max(.5rem,env(safe-area-inset-left))] pb-[env(safe-area-inset-bottom)] pr-[max(.5rem,env(safe-area-inset-right))] backdrop-blur md:hidden"
>
  {PHONE_TABS.map(({ href, label, Icon }) => {
    const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
    const count = counts[href] ?? 0;
    return <Link key={href} href={href} aria-current={active ? "page" : undefined} className={cn("relative flex min-h-11 flex-col items-center justify-center gap-0.5 rounded-lg px-2 text-xs", active ? "text-accent" : "text-dim")}>
      <Icon size={19} aria-hidden />
      <span>{label}</span>
      {count > 0 && <span className="num absolute right-3 top-1 rounded-full bg-accent px-1.5 text-[11px] font-bold text-ink" aria-label={`${count} open decisions`}>{count}</span>}
    </Link>;
  })}
  <button type="button" aria-current={moreActive ? "page" : undefined} onClick={() => setMore(true)} className={cn("flex min-h-11 flex-col items-center justify-center gap-0.5 rounded-lg px-2 text-xs", moreActive ? "text-accent" : "text-dim")}>
    <MoreHorizontal size={19} aria-hidden />
    <span>More</span>
  </button>
</nav>
<Dialog open={more} onClose={() => setMore(false)} title="Around the agency">
  <nav aria-label="More sections" className="divide-y divide-line">
    {MORE_NAV.map(({ href, label, Icon }) => <Link key={href} href={href} onClick={() => setMore(false)} className="flex min-h-11 items-center gap-3 py-3 text-sm">
      <Icon size={18} aria-hidden />
      <span>{label}</span>
    </Link>)}
  </nav>
</Dialog>
```

- [ ] **Step 4: Reshape status and week controls without changing behavior**

Apply these exact phone behaviors:

```tsx
// StatusBar outer classes
"sticky top-0 z-20 flex min-h-14 items-center gap-3 border-b border-line bg-panel/90 px-[max(1rem,env(safe-area-inset-left))] py-2 pt-[max(.5rem,env(safe-area-inset-top))] pr-[max(1rem,env(safe-area-inset-right))] backdrop-blur"
```

Keep week/window on the leading side and Cash/Weekly net on the trailing side. Hide Reputation below `sm` and capacity below `2xl`; allow neither primary group to wrap on phones.

For `ContinueButton`'s floating variant, add `data-phone-chrome` and use a fixed 64px phone action toolbar positioned immediately above the 64px tab bar:

```tsx
"fixed inset-x-0 bottom-[calc(64px+env(safe-area-inset-bottom))] z-30 border-t border-line bg-panel/95 px-[max(.75rem,env(safe-area-inset-left))] py-2 pr-[max(.75rem,env(safe-area-inset-right))] backdrop-blur md:bottom-0 xl:hidden"
```

The permanent phone row contains only Review and Continue. Hide the automatic-advance/status row below `md`; retain automatic advancement through the existing “Skip these and advance to next event” action in the review sheet.

- [ ] **Step 5: Make all dialogs phone bottom sheets and move overlays above chrome**

Use bottom alignment and safe-area padding below `sm`, preserving centered desktop dialogs and the current focus code:

```tsx
// backdrop
`fixed inset-0 z-40 flex items-end bg-black/70 px-0 pt-[max(1rem,env(safe-area-inset-top))] backdrop-blur-sm sm:items-center sm:justify-center sm:p-4 ${side ? "justify-end" : "justify-center"}`

// non-side panel
`anim-rise max-h-[calc(100dvh-env(safe-area-inset-top)-1rem)] w-full overflow-y-auto rounded-t-2xl border border-line bg-panel pb-[env(safe-area-inset-bottom)] shadow-2xl shadow-black/70 outline-none sm:max-h-[85vh] sm:rounded-xl ${wide ? "sm:max-w-2xl" : "sm:max-w-md"}`
```

Change all four shared `buttonClass` variants from `min-h-10` to `min-h-11`. Position phone toasts with `inset-x-3`, `w-auto`, and `bottom-[calc(136px+env(safe-area-inset-bottom))]`, restoring the existing desktop location at `md`.

- [ ] **Step 6: Reserve exactly the fixed phone chrome height**

In `web/app/(game)/layout.tsx`, give the app wrapper `min-h-dvh` and update `main` to:

```tsx
<main className="min-w-0 flex-1 px-[max(1rem,env(safe-area-inset-left))] py-4 pb-[calc(152px+env(safe-area-inset-bottom))] pr-[max(1rem,env(safe-area-inset-right))] md:px-6 md:pb-40 xl:pb-6">
```

The 152px reserve covers the 64px tab bar, 64px action bar, borders, and breathing room without the old 288px blank area.

- [ ] **Step 7: Run focused tests and type checking**

Run: `cd web && npm test -- --run components/shell/nav-rail.test.tsx components/dialog.test.tsx components/continue-button.test.tsx`

Expected: PASS.

Run: `cd web && npx tsc --noEmit`

Expected: exit 0.

- [ ] **Step 8: Commit the phone shell**

```bash
git add web/components/shell/nav-rail.tsx web/components/shell/nav-rail.test.tsx web/components/shell/status-bar.tsx web/components/continue-button.tsx web/components/dialog.tsx web/components/dialog.test.tsx web/components/toaster.tsx web/components/ui.tsx 'web/app/(game)/layout.tsx'
git commit -m "feat: add iPhone game shell"
```

---

### Task 3: iPhone screen density and retained artwork

**Files:**
- Modify: `web/app/globals.css:22-269`
- Modify: `web/components/scene-banner.tsx:9-17`
- Modify: `web/components/office-scene.tsx:6-42`
- Modify: `web/app/(game)/page.tsx:14-25`
- Modify: `web/app/(game)/finances/page.tsx:20-58`
- Modify: `web/components/investment-desk.tsx:58-116`
- Modify: `web/components/agency-desk.tsx:40-80`
- Modify: `web/components/career-panel.tsx:70-96`
- Modify: `web/components/negotiation/shared.tsx:80-104`
- Modify: `web/app/(game)/scouting/scouting-panels.tsx:400-445`
- Modify: `web/app/(game)/careers/page.tsx:14-29`
- Modify: `web/app/(game)/world/page.tsx:1-12`
- Modify: `web/app/new-game/page.tsx:18-53`
- Modify: `web/app/new-game/new-game-form.tsx:69-170`
- Modify: `web/app/new-game/created/page.tsx:20-44`
- Modify: `web/app/game-over/page.tsx:20-53`
- Modify: `web/e2e/game-flow.spec.cjs:146-184`

**Interfaces:**
- Consumes: existing screen data, artwork paths, `SceneBanner`, `OfficeScene`, `Panel`, `StatTile`, `buttonClass`, and Playwright's page API.
- Produces: single-column phone cards and forms, edge-to-edge phone artwork treatment, and safe-area-aware entry/exit screens. No component props or game behavior change.

- [ ] **Step 1: Extend the phone browser test so it fails on current geometry**

Inside the existing `agency expansion is usable on desktop and a narrow phone` test, use the approved iPhone viewport and assert chrome and target geometry:

```js
await page.setViewportSize({width:390,height:844});
await page.goto('/');
const tabs = page.getByRole('navigation',{name:'Sections'});
const continueButton = page.getByRole('button',{name:'Continue to next week'}).filter({visible:true});
const officeStats = page.locator('section').filter({hasText:'Agency balance'}).first();
await expect(tabs).toBeVisible();
await expect(page.getByRole('link',{name:'Scouting'})).toBeVisible();
expect(await officeStats.evaluate(element => getComputedStyle(element).gridTemplateColumns.split(' ').length)).toBe(1);
const tabsBox = await tabs.boundingBox();
const continueBox = await continueButton.boundingBox();
expect(continueBox.y + continueBox.height).toBeLessThanOrEqual(tabsBox.y + 1);
expect(continueBox.height).toBeGreaterThanOrEqual(44);
expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBeTruthy();

await page.getByRole('button',{name:'More'}).click();
const sheet = page.getByRole('dialog',{name:'Around the agency'});
const sheetBox = await sheet.boundingBox();
expect(sheetBox.y).toBeGreaterThanOrEqual(0);
expect(sheetBox.y + sheetBox.height).toBeLessThanOrEqual(844);
for (const name of ['Agency','Finances','World','Market','Careers','Stocks','Headquarters','Season review']) {
  await expect(sheet.getByRole('link',{name})).toBeVisible();
}
```

- [ ] **Step 2: Run the focused end-to-end test and verify it fails**

Run: `cd web && npx playwright test e2e/game-flow.spec.cjs --grep "agency expansion"`

Expected: FAIL because the office summary still renders two columns at 390px; the geometry assertions guard the shell completed in Task 2.

- [ ] **Step 3: Add restrained phone type, safe-area, and image rules**

Append one mobile media block to `web/app/globals.css`:

```css
@media (max-width: 767px) {
  html,
  body {
    min-height: 100dvh;
    font-size: 17px;
    overscroll-behavior-y: none;
  }

  body {
    background-attachment: scroll;
  }

  .t-title {
    font-size: 1.75rem;
  }

  .scene-banner {
    min-height: 190px;
    margin-inline: -1rem;
    border-left: 0;
    border-right: 0;
    border-radius: 0;
  }

  .office-scene svg {
    min-height: 230px;
  }

  body:has(input:focus, select:focus, textarea:focus) [data-phone-chrome] {
    display: none;
  }
}
```

Update `SceneBanner` without changing its props or image paths:

```tsx
<section className="scene-banner relative isolate overflow-hidden rounded-xl border border-line">
  <Image src={`/images/${image}.jpg`} alt="" fill priority sizes="(min-width: 1280px) 65vw, 100vw" className="object-cover" />
  <div className="absolute inset-0 bg-gradient-to-r from-[#0b1814]/95 via-[#0b1814]/80 to-[#0b1814]/35 sm:to-[#0b1814]/10" />
  <div className="relative max-w-xl px-4 py-6 sm:px-7 sm:py-9">
    <p className="t-label text-[#dfcc99]">{eyebrow}</p>
    <h2 className="office-title mt-2 text-3xl text-[#fff6e4]">{title}</h2>
    <p className="mt-3 max-w-sm text-sm leading-relaxed text-[#ece8d9]">{description}</p>
  </div>
</section>
```

Keep `OfficeScene`'s existing SVG and data. Change the “Manage office” link to
`min-h-11`, and change the footer to this horizontally scrollable phone row:

```tsx
<div className="flex gap-2 overflow-x-auto border-t border-[#bba477]/20 bg-[#182a23] p-3">
  {[["/agency", "Staff & departments"], ["/scouting", "Scouting room"], ["/market", "Deal room"], ["/careers", "Client lounge"], ["/season-review", "Trophy shelf"]].map(([href, label]) => <Link key={href} href={href} className="flex min-h-11 shrink-0 items-center rounded-lg border border-[#bba477]/25 px-3 py-2 text-xs text-[#e5ddc6] transition hover:bg-white/10">{label} <span aria-hidden>↗</span></Link>)}
</div>
```

- [ ] **Step 4: Make top-level phone information and forms single-column**

Apply these exact class replacements:

```text
web/app/(game)/page.tsx:
  "grid grid-cols-2 gap-3 2xl:grid-cols-4" -> "grid gap-3 sm:grid-cols-2 2xl:grid-cols-4"

web/app/(game)/finances/page.tsx:
  "grid grid-cols-2 gap-3 2xl:grid-cols-4" -> "grid gap-3 sm:grid-cols-2 2xl:grid-cols-4"

web/components/investment-desk.tsx:
  "grid grid-cols-2 gap-3 2xl:grid-cols-4" -> "grid gap-3 sm:grid-cols-2 2xl:grid-cols-4"

web/components/agency-desk.tsx:
  "grid grid-cols-2 gap-3 2xl:grid-cols-4" -> "grid gap-3 sm:grid-cols-2 2xl:grid-cols-4"
  "grid grid-cols-2 gap-2" -> "grid gap-2 sm:grid-cols-2"

web/app/new-game/new-game-form.tsx:
  "grid grid-cols-2 gap-3" -> "grid gap-3 sm:grid-cols-2"
  load-slot flex rows -> "grid gap-2 sm:grid-cols-[1fr_auto]"
```

On `new-game`, `new-game/created`, and `game-over`, replace `min-h-screen` with `min-h-dvh`, add top padding using `env(safe-area-inset-top)`, bottom padding using `env(safe-area-inset-bottom)`, and use shared `buttonClass` for the full-width primary links. The retained scouting image remains the new-game hero.

Remove same-direction nested phone scrolling by changing the existing timeline,
prior-offer, scout-list, staff-portfolio, and rival-list containers from
`max-h-* overflow-y-auto` to `md:max-h-* md:overflow-y-auto` in
`career-panel.tsx`, `negotiation/shared.tsx`, `scouting-panels.tsx`,
`agency-desk.tsx`, `careers/page.tsx`, and `world/page.tsx`. Dialog sheets keep
their own vertical scrolling because the covered page is inert.

In the stock-trading phone test, focus the “Number of shares” input and assert
`[data-phone-chrome]` is hidden, then blur it and assert the phone navigation is
visible again. This pins the keyboard behavior without adding JavaScript state.

- [ ] **Step 5: Run the phone journey and take verification screenshots**

Run: `cd web && npx playwright test e2e/game-flow.spec.cjs --grep "agency expansion"`

Expected: PASS and `/tmp/fa-market-mobile.png` is refreshed at 390px width.

Run: `cd web && npx playwright test e2e/game-flow.spec.cjs --grep "stock trading"`

Expected: PASS and `/tmp/fa-investments-mobile.png` shows no document overflow.

- [ ] **Step 6: Commit phone screen treatment**

```bash
git add web/app/globals.css web/components/scene-banner.tsx web/components/office-scene.tsx web/components/career-panel.tsx web/components/negotiation/shared.tsx web/components/investment-desk.tsx web/components/agency-desk.tsx 'web/app/(game)/page.tsx' 'web/app/(game)/finances/page.tsx' 'web/app/(game)/scouting/scouting-panels.tsx' 'web/app/(game)/careers/page.tsx' 'web/app/(game)/world/page.tsx' web/app/new-game/page.tsx web/app/new-game/new-game-form.tsx web/app/new-game/created/page.tsx web/app/game-over/page.tsx web/e2e/game-flow.spec.cjs
git commit -m "feat: adapt game screens for iPhone"
```

---

### Task 4: Full-flow verification and user documentation

**Files:**
- Modify: `documentation/ui/app-shell.md:1-95`
- Modify: `documentation/changelog.md:1-25`
- Modify only if verification finds a regression: files already listed in Tasks 1-3

**Interfaces:**
- Consumes: the completed PWA manifest, phone shell, shared mobile primitives, existing API contract, and existing test suites.
- Produces: documented install behavior and authoritative evidence that the browser, API, and engine flows still work together.

- [ ] **Step 1: Document the shipped phone shell and install boundary**

Add this current-state note to `documentation/ui/app-shell.md`:

```markdown
Updated 2026-09-19: the phone shell is an installable iPhone-first PWA. Its
bottom tab bar contains Office, Clients, Scouting and More; decision review and
week advancement sit in a separate action toolbar above it. All fixed chrome
uses iPhone safe-area insets, dialogs become bottom sheets below 768px, and
primary controls retain 44px touch targets. The manifest launches from the Home
Screen in standalone portrait mode. Gameplay remains online because the Python
simulation and saves are authoritative on the FastAPI server.
```

Add a matching changelog entry covering installability, safe areas, bottom tabs,
bottom sheets, retained artwork, and the explicit lack of offline simulation.

```markdown
## 2026-09-19 — iPhone-first PWA

- **Added:** installable standalone PWA metadata and Home Screen icons.
- **Changed:** phone navigation now uses Office, Clients, Scouting and More tabs,
  with decision review and week advancement in a separate safe-area-aware action
  toolbar.
- **Improved:** phone screens use single-column cards, 44px touch targets and
  bottom-sheet dialogs while retaining the existing editorial artwork and game
  flow.
- **Boundary:** gameplay still requires the FastAPI server; no offline simulation
  or alternate game engine was added.
```

- [ ] **Step 2: Run every component test and TypeScript check**

Run: `cd web && npm test -- --run`

Expected: all component tests PASS.

Run: `cd web && npx tsc --noEmit`

Expected: exit 0.

- [ ] **Step 3: Run the production build**

Run: `cd web && npm run build`

Expected: Next.js build succeeds and lists `/manifest.webmanifest` without type or prerender errors.

- [ ] **Step 4: Run the Python contract and engine suite**

Run: `'/Users/charles/Documents/Custom Logic AI/code/football_agent_game/.venv/bin/python' -m pytest -q -p no:cacheprovider`

Expected: all Python tests PASS, proving the unchanged API and engine remain compatible.

- [ ] **Step 5: Run the complete browser journey**

Run: `cd web && npm run test:e2e`

Expected: every Playwright test PASS across new game, scouting, signing, agency management, decisions, investments, desktop, and 390×844 phone routes.

- [ ] **Step 6: Inspect the two phone screenshots**

Open `/tmp/fa-market-mobile.png` and `/tmp/fa-investments-mobile.png`. Verify the image banners remain present where expected, text is legible at 390px, the action toolbar sits above the tab bar, content is not hidden behind fixed chrome, and no control is clipped by a safe area.

- [ ] **Step 7: Check the final diff and commit documentation**

Run: `git diff --check`

Expected: no whitespace errors.

```bash
git add documentation/ui/app-shell.md documentation/changelog.md
git commit -m "docs: describe iPhone PWA experience"
```

- [ ] **Step 8: Record final evidence**

Run: `git status --short --branch`

Expected: `## codex/iphone-port` with no uncommitted files.

Run: `git log --oneline master..HEAD`

Expected: the design, installability, phone shell, screen adaptation, and documentation commits appear in order.
