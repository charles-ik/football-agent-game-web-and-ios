# Native iPhone edition

**Status:** shipped · **Added:** 2026-09-26

## What it is

`ios/FootballAgent.xcodeproj` builds a self-contained iPhone game in SwiftUI. The target has no WebKit import, HTTP endpoint, local-network permission, Python or Node.js runtime. The Python and web editions remain in the repository as the original tuning reference, but the installed app creates, simulates and saves its world entirely on-device.

The app targets iOS 17+, iPhone and portrait orientation. It uses native tab, navigation, list, form, sheet, chart and confirmation components. Frequent actions meet the 44pt touch target, content respects the Dynamic Island and home indicator, and the persistent Continue control sits directly above the five-item tab bar.

## Gameplay and progression

The native edition includes seeded worlds, weekly seasons and windows, report ranges, shortlists, three-round representation and transfer negotiations, client trust and playing time, development and injuries, transfers and renewals, loans and returns, career goals and promises, club relationships and pitches, rivals and poaching, staff portfolios, departments and specialization, objectives and milestone rewards, headquarters and insolvency, fictional stocks, league tables, alumni and game over.

Office derives one useful next move from live state. Core agency, client, scouting, finance and headquarters tools start available. Market opens after the first additional client; staff, departments, specialization and loans open after the first commission; stocks open at £100,000 cash with a positive recurring budget. Locked areas stay visible and name the exact requirement.

## Runtime boundaries

- `GameEngine` owns validation, hidden ratings, negotiation thresholds, deterministic weekly systems, decisions and progression. Actions mutate a copy and commit it only on success.
- `GameState` is plain `Codable`, `Equatable` and `Sendable` data. Its seed, authored world and complete career state make reopening deterministic.
- `GameStore` is the main-actor boundary used by SwiftUI. It serializes actions, prevents overlapping time advances and autosaves after each successful mutation.
- Views display report ranges and qualitative negotiation information; they do not calculate rules or reveal true prospect ability, potential or acceptance thresholds.

The stable entry points are `ios/FootballAgent/GameEngine.swift`, `GameModels.swift`, `GameStore.swift` and `ContentView.swift`.

## Saves and recovery

Each slot is a versioned JSON file below the app's Application Support directory. Before replacement, the previous file is copied to a `.bak.json` sibling. A corrupt or newer-schema file is preserved and reported in the UI; it is never silently replaced. Successful in-memory play remains available if a write fails.

## Build and verification

Open `ios/FootballAgent.xcodeproj`, select the FootballAgent scheme and a connected iPhone, then press Run. Automatic signing reads the bundle identifier and team from `ios/Config.xcconfig`.

The `FootballAgentTests` target checks deterministic creation and advancement, scouting uncertainty, transactional refusals, transfer commission and history, bounded event advancement, JSON determinism, atomic autosave round trips and corrupt-save preservation.
