# iPhone-First PWA Design

## Goal

Turn the existing Football Agent web game into a simple, installable,
iPhone-first progressive web app without rewriting the simulation or changing
the game's current flow. Preserve the existing editorial artwork and the full
set of playable routes.

## Product boundaries

- The Python simulation, FastAPI service, DTOs, save format, and game rules stay
  authoritative and unchanged.
- The existing Next.js application remains the only game frontend. A thin
  SwiftUI `WKWebView` shell packages that same PWA for direct installation from
  Xcode; it contains no duplicate screens or game rules.
- Desktop behavior remains usable. The redesigned shell and component rules
  apply primarily below the existing `md` breakpoint.
- The app is installable and launches in standalone mode, but offline gameplay
  is out of scope because simulation state and saves live on the server.
- No push notifications, background sync, or App Store distribution workflow
  is included.

## iPhone application shell

The phone layout uses three vertically stacked zones:

1. A compact, safe-area-aware status header showing the current week, transfer
   window state, cash, and weekly net.
2. One vertically scrolling content region with a single-column reading order.
3. Fixed bottom controls made of an action toolbar above a four-item tab bar.

The bottom tabs are **Office**, **Clients**, **Scouting**, and **More**. They are
always present on game screens and are used only for navigation. More opens a
bottom sheet containing Agency, Finances, World, Market, Careers, Stocks,
Headquarters, and Season Review.

The action toolbar contains the two global game actions: review open decisions
and advance one week. The advance action is visually primary and remains
separate from navigation. Automatic advancement to the next event remains
available from the review flow rather than occupying permanent phone chrome.

All fixed chrome uses `env(safe-area-inset-*)`; the page reserves its combined
height so content and controls never overlap. Important interactive elements
have a minimum 44 by 44 CSS-pixel target and visible focus styling.

## Screen treatment

Phone screens use one vertical scroll container and avoid nested vertical
scrolling. Existing tables collapse into cards or horizontally scroll only when
the data genuinely requires column comparison. Primary actions fill the
available width; related secondary actions may share a row when both retain
44-pixel targets.

Existing office, scouting, career, headquarters, investment, and agency images
remain in their current journeys. On phones they render as shallow, edge-to-edge
scene banners with readable text overlays and no extra decorative imagery.

Dialogs become bottom sheets on phones: aligned to the bottom edge, rounded at
the top, safe-area padded, and capped below the status area. They retain the
current focus trap, Escape behavior, backdrop dismissal, and focus restoration.
Desktop dialogs remain centered.

The visual language stays restrained: the existing forest green, warm ivory,
and agency accent colors remain; typography, borders, and motion are simplified
only where needed to reduce density. Reduced-motion preferences continue to be
honored.

## PWA behavior

Next.js supplies a web app manifest with:

- name and short name: Football Agent
- a stable `/` app identifier and start URL
- `display: "standalone"`
- portrait-primary orientation
- the existing dark green background and theme colors
- purpose-built 192px and 512px icons, including a maskable icon

Root metadata declares the manifest, `apple-mobile-web-app-capable`, the Apple
status-bar style, an Apple touch icon, and a viewport using
`viewport-fit=cover`. The browser version remains fully usable when the app has
not been installed.

No service worker is added. Caching a server-rendered, session-bound game would
create stale or misleading state without providing genuine offline play.

## Xcode wrapper

`ios/FootballAgent.xcodeproj` is a shared-scheme iPhone application using
SwiftUI and `WKWebView`. It loads the PWA from a build-configured URL and fills
the device screen so the web app's own safe-area-aware chrome remains
authoritative. The wrapper adds only native loading and connection-failure
states, pull to refresh, back/forward gestures, and external-link handoff.

The checked-in development configuration targets
`http://MacBook-Pro.local:3000`, allowing a physical iPhone on the same local
network to reach the Mac. A `make dev-ios` command runs the existing FastAPI and
Next.js servers with the web server bound to the LAN. The Info.plist declares
local-network usage and permits local networking without allowing arbitrary
internet HTTP traffic.

The Xcode target uses automatic signing and a shared Run scheme. Xcode chooses
the Apple development team already configured on the Mac; no certificate,
profile, or account data is committed. Selecting the connected iPhone and
pressing Run installs the wrapper. A hosted HTTPS build later requires only a
configuration URL change.

## Data flow and failures

Server Components and Server Actions continue to call FastAPI exactly as they
do today. Session cookies, mutation revision checks, negotiation handles, and
autosaves are unchanged.

Loss of connectivity or an expired session continues through the existing
error and redirect paths. Fixed toolbars must not obscure toasts, errors,
dialogs, or focused form controls when the iPhone keyboard is visible.

## Verification

- Component tests cover active tab state, decision counts, More-sheet routes,
  and phone dialog semantics.
- Metadata tests verify the manifest, standalone mode, icons, theme colors, and
  viewport configuration.
- The existing browser journey is extended at a 390 by 844 viewport to cover
  new game, office, navigation, decision review, week advancement, scouting,
  clients, and every secondary route.
- Browser assertions verify no horizontal document overflow, no overlap between
  content and fixed bottom chrome, and 44-pixel minimum primary tap targets.
- Type checking, component tests, production build, Python tests, and the full
  end-to-end journey must pass.
- `xcodebuild` must compile the shared scheme for an iOS Simulator destination,
  and the project must be opened in Xcode ready for automatic signing and a
  physical-device Run.

## References

- [Apple Human Interface Guidelines: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Apple Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple Human Interface Guidelines: Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Apple Human Interface Guidelines: Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views)
- [WebKit: Designing Websites for iPhone X](https://webkit.org/blog/7929/designing-websites-for-iphone-x/)
- [WebKit: Web Push for Web Apps on iOS and iPadOS](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/)
