# Native iPhone Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the WebKit wrapper with a complete offline SwiftUI version of Football Agent, including every existing game system and improved progression.

**Architecture:** A pure Swift `GameEngine` owns all state transitions behind four static methods; a main-actor `GameStore` owns persistence and presentation state; SwiftUI views only render safe read models and send `GameAction` values. Content and artwork are bundled in the iOS target, with no network or Python runtime.

**Tech Stack:** Swift 5, SwiftUI, Observation/Combine, Foundation Codable, Swift Charts, XCTest, Xcode 26; no third-party packages.

**Spec:** `docs/superpowers/specs/2026-09-26-native-iphone-game-design.md`

## Global Constraints

- iOS deployment target remains 17.0 and portrait-only.
- The iPhone target must contain no `WebKit` import, HTTP endpoint, local-network permission or Python/Node invocation.
- All existing gameplay systems listed in the spec ship in the native app.
- Hidden ability, potential and negotiation thresholds never appear in public view models.
- All successful actions and weekly advances autosave atomically.
- Reuse the existing five editorial images and app icon.
- Add no third-party dependency.

## Review Focus

- A failed action must leave the complete game state unchanged; pin with an unaffordable-HQ test in Task 2.
- Reopening a save must not reroll scouting, offers or stocks; pin with round-trip determinism in Task 3.
- Repeated Continue taps must not advance twice concurrently; pin through the main-actor store test in Task 3.
- Locked secondary systems must remain discoverable with exact requirements; pin progression requirements in Task 2.
- A corrupt or future-schema save must remain on disk and surface recovery UI; pin both cases in Task 3.

---

### Task 1: Native domain model and deterministic world

**Files:**
- Create: `ios/FootballAgent/GameModels.swift`
- Create: `ios/FootballAgent/GameContent.swift`
- Create: `ios/FootballAgent/SeededRandom.swift`
- Create: `ios/FootballAgentTests/GameEngineTests.swift`
- Modify: `ios/FootballAgent.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `GameState`, `GameAction`, `ActionOutcome`, `GameEvent`, `GameDecision`, `AdvanceMode`, `GameContent`, `SeededRandom`.
- Consumes: the authored values in `football_agent/data/*.json` as the source of compiled native content.

- [ ] **Step 1: Add the native model and first failing creation test**

```swift
func testNewGameIsDeterministicAndPlayable() {
    let first = GameEngine.newGame(name: "Northbank", seed: 42)
    let second = GameEngine.newGame(name: "Northbank", seed: 42)
    XCTAssertEqual(first, second)
    XCTAssertEqual(first.agency.cash, 75_000)
    XCTAssertEqual(first.clients.count, 1)
    XCTAssertEqual(first.scouts.count, 1)
}
```

- [ ] **Step 2: Implement plain Codable state**

```swift
struct GameState: Codable, Equatable, Sendable {
    var schemaVersion = 1
    var seed: UInt64
    var week = 1
    var agency: Agency
    var players: [Player]
    var clients: [Client]
    var scouts: [Scout]
    var reports: [ScoutingReport] = []
    var offers: [TransferOffer] = []
    var loans: [Loan] = []
    var events: [GameEvent] = []
    var financeHistory: [FinanceWeek] = []
    var investments = InvestmentPortfolio()
    var progression = Progression()
    var gameOverReason: String?
}
```

Include typed models for clubs, regions, staff, departments, objectives, histories, rivals, negotiations, holdings and league records. IDs are UUID strings created by the deterministic generator.

- [ ] **Step 3: Implement stable independent random streams**

```swift
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64, week: Int = 0, stream: String = "world") {
        state = seed ^ Self.fnv1a("\(week):\(stream)")
    }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}
```

- [ ] **Step 4: Compile authored clubs, regions, names and tuned rules into `GameContent`**

Use the existing fictional names and numeric balance values; do not create a second set of clubs or progression numbers.

- [ ] **Step 5: Add the XCTest target and run the creation test**

Run: `xcodebuild test -project ios/FootballAgent.xcodeproj -scheme FootballAgent -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/FootballAgentNativeTests`

Expected: the deterministic new-game test passes.

- [ ] **Step 6: Commit**

```bash
git add ios/FootballAgent ios/FootballAgentTests ios/FootballAgent.xcodeproj/project.pbxproj
git commit -m "feat: add native football game model"
```

### Task 2: Complete native game engine and progression

**Files:**
- Create: `ios/FootballAgent/GameEngine.swift`
- Modify: `ios/FootballAgent/GameModels.swift`
- Modify: `ios/FootballAgentTests/GameEngineTests.swift`

**Interfaces:**
- Consumes: `GameState`, `GameContent`, `SeededRandom` from Task 1.
- Produces: the complete `GameEngine` interface from the spec and safe computed summaries used by views.

- [ ] **Step 1: Write interface-level tests for the core loop**

```swift
func testScoutReportsNarrowAndNeverExposeTruth() {
    var game = GameEngine.newGame(name: "Northbank", seed: 42)
    let scout = try! XCTUnwrap(game.scouts.first)
    XCTAssertTrue(GameEngine.perform(.assignScout(scout.id, regionID: "north"), on: &game).ok)
    _ = GameEngine.advance(.weeks(8), state: &game)
    let report = try! XCTUnwrap(game.reports.first)
    XCTAssertGreaterThan(report.abilityHigh, report.abilityLow)
    XCTAssertNil(report.exposedTrueAbility)
}

func testFailedActionDoesNotMutateState() {
    var game = GameEngine.newGame(name: "Northbank", seed: 42)
    game.agency.cash = 0
    let before = game
    XCTAssertFalse(GameEngine.perform(.upgradeHeadquarters, on: &game).ok)
    XCTAssertEqual(game, before)
}
```

- [ ] **Step 2: Implement validated player actions**

`GameAction` covers scout assignment/focus/hiring, shortlist, client approach and negotiation, seek/stop move, transfer/renewal negotiation, conversations, promises, pitches, loans, staff and portfolios, departments, specialization, objective, HQ, stocks and releasing clients. Implement actions transactionally by mutating a copy and assigning it back only on success.

```swift
static func perform(_ action: GameAction, on state: inout GameState) -> ActionOutcome {
    var candidate = state
    let outcome = apply(action, to: &candidate)
    if outcome.ok { state = candidate }
    return outcome
}
```

- [ ] **Step 3: Implement bounded native negotiations**

Three-round commission and package negotiations use hidden thresholds, qualitative hints, improving counters and increasing walk-away risk. Opening an approach spends its single negotiation attempt.

- [ ] **Step 4: Implement the ordered weekly systems**

Add private functions for finance, stocks, development/contracts, trust/careers, scouting, transfers/loans, rivals, leagues and progression. Each receives `inout GameState` and its own `SeededRandom` stream.

- [ ] **Step 5: Implement derived decisions and next action**

```swift
static func decisions(in state: GameState) -> [GameDecision]
static func nextMove(in state: GameState) -> NextMove
static func featureAccess(in state: GameState) -> [GameFeature: FeatureAccess]
```

Sort decisions by severity, actionability and deadline. Implement the exact staged unlock requirements from the spec.

- [ ] **Step 6: Add parity and progression tests**

Test transfers/loans/commission, trust and departures, contracts, staff/departments, objectives/milestones, deterministic stocks/trades, league rollover, insolvency/downsize/game over, unlock labels and advance-to-event's 12-week bound.

- [ ] **Step 7: Run tests and commit**

```bash
xcodebuild test -project ios/FootballAgent.xcodeproj -scheme FootballAgent -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/FootballAgentNativeTests
git add ios/FootballAgent ios/FootballAgentTests
git commit -m "feat: port the full game engine to Swift"
```

### Task 3: Native save store

**Files:**
- Create: `ios/FootballAgent/GameStore.swift`
- Create: `ios/FootballAgentTests/GameStoreTests.swift`
- Modify: `ios/FootballAgent.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `GameEngine` and `GameState`.
- Produces: `@MainActor final class GameStore: ObservableObject` with `game`, `slots`, `perform`, `advance`, `newGame`, `load`, `delete` and `lastMessage`.

- [ ] **Step 1: Write round-trip, corrupt-save and serialization tests**

```swift
func testSaveRoundTripPreservesNextWeek() throws {
    let store = GameStore(directory: temporaryDirectory)
    store.newGame(name: "Northbank", seed: 42, slot: "one")
    store.advance(.oneWeek)
    let expected = store.game
    let reopened = GameStore(directory: temporaryDirectory)
    reopened.load(slot: "one")
    XCTAssertEqual(reopened.game, expected)
}
```

- [ ] **Step 2: Implement atomic JSON saves with backup**

Encode to a temporary sibling, copy the old file to `.bak`, then use `FileManager.replaceItemAt`. Never remove an unreadable save automatically.

- [ ] **Step 3: Serialize mutations on the main actor**

Use an `isAdvancing` guard around advance; successful actions save immediately and failed actions only publish their refusal.

- [ ] **Step 4: Run store tests and commit**

```bash
xcodebuild test -project ios/FootballAgent.xcodeproj -scheme FootballAgent -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/FootballAgentNativeTests
git add ios/FootballAgent/GameStore.swift ios/FootballAgentTests ios/FootballAgent.xcodeproj/project.pbxproj
git commit -m "feat: add native autosaves"
```

### Task 4: Native SwiftUI game flow

**Files:**
- Replace: `ios/FootballAgent/ContentView.swift`
- Replace: `ios/FootballAgent/FootballAgentApp.swift`
- Create: `ios/FootballAgent/NativeTheme.swift`
- Create: `ios/FootballAgent/OfficeView.swift`
- Create: `ios/FootballAgent/ClientsView.swift`
- Create: `ios/FootballAgent/ScoutingView.swift`
- Create: `ios/FootballAgent/MarketView.swift`
- Create: `ios/FootballAgent/MoreViews.swift`
- Modify: `ios/FootballAgent/Assets.xcassets/**`

**Interfaces:**
- Consumes: `GameStore`, safe `GameEngine` summaries and bundled images.
- Produces: the complete native UI and accessibility surface.

- [ ] **Step 1: Replace the launch flow**

`FootballAgentApp` creates one `@StateObject GameStore`. `ContentView` shows native save/new-game UI when no slot is loaded and `GameShell` otherwise.

- [ ] **Step 2: Build the five-tab shell and Continue bar**

```swift
TabView(selection: $selection) {
    NavigationStack { OfficeView() }.tabItem { Label("Office", systemImage: "building.2") }
    NavigationStack { ClientsView() }.tabItem { Label("Clients", systemImage: "person.2") }
    NavigationStack { ScoutingView() }.tabItem { Label("Scouting", systemImage: "magnifyingglass") }
    NavigationStack { MarketView() }.tabItem { Label("Market", systemImage: "arrow.left.arrow.right") }
    NavigationStack { MoreView() }.tabItem { Label("More", systemImage: "ellipsis") }
}
.safeAreaInset(edge: .bottom) { ContinueBar() }
```

- [ ] **Step 3: Build Office, Clients and Scouting**

Use native cards/lists for next move, stage progress, decisions, event feed, roster, dossiers, career history, scouts, assignments and ranged reports. All buttons call `GameStore.perform`.

- [ ] **Step 4: Build Market and native negotiation sheets**

Render transfers, renewals, pitches, relationships, loan talks and clubs. Commission/package talks use sliders, native feedback and a visible rounds-left count.

- [ ] **Step 5: Build every More destination**

Agency includes staff, portfolios, departments, identity, specialization and objective. Finance uses Swift Charts. Stocks supports review-before-trade. World shows leagues, clubs and rivals. Headquarters shows capacity/cost deltas. Season Review shows objectives, milestones and history. Save controls support switching, new game and confirmed deletion.

- [ ] **Step 6: Bundle artwork and verify accessibility**

Create image sets for `agency-desk`, `career-tunnel`, `headquarters`, `investment-city` and `scouting-ground`. Verify Dynamic Type, VoiceOver labels, reduced-motion behavior, empty states and minimum control heights.

- [ ] **Step 7: Build and commit**

```bash
xcodebuild -project ios/FootballAgent.xcodeproj -scheme FootballAgent -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO -derivedDataPath /tmp/FootballAgentNativeBuild build
git add ios
git commit -m "feat: build the native SwiftUI game"
```

### Task 5: Remove wrapper configuration, document and verify on device

**Files:**
- Modify: `ios/FootballAgent/Info.plist`
- Modify: `ios/Config.xcconfig`
- Modify: `ios/README.md`
- Modify: `README.md`
- Modify: `docs/how-to-run.md`
- Modify: `documentation/changelog.md`
- Modify: `documentation/ui/app-shell.md`
- Modify: `.gitignore`
- Modify: `Makefile`

**Interfaces:**
- Consumes: the finished native app.
- Produces: a server-free Xcode workflow and current documentation.

- [ ] **Step 1: Remove wrapper-only settings**

Delete `FootballAgentHost`, `FootballAgentPort`, `FootballAgentScheme`, ATS local networking and local-network usage text. Remove `FOOTBALL_AGENT_*` build settings and the `dev-ios` requirement from iOS instructions.

- [ ] **Step 2: Ignore Xcode user state and update durable docs**

Add `ios/**/xcuserdata/` to `.gitignore`. State plainly that the iPhone app is offline SwiftUI, while Python/web remain separate playable reference versions.

- [ ] **Step 3: Run the complete verification matrix**

```bash
xcodebuild test -project ios/FootballAgent.xcodeproj -scheme FootballAgent -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/FootballAgentNativeTests
xcodebuild -project ios/FootballAgent.xcodeproj -scheme FootballAgent -configuration Debug -destination id=CA8FB90F-300E-5560-B369-902BBB49988B -allowProvisioningUpdates -derivedDataPath /tmp/FootballAgentNativeDevice build
rg -n 'WebKit|http://|https://|FOOTBALL_AGENT_HOST|NSLocalNetworkUsageDescription' ios
git diff --check
```

Expected: tests and signed device build pass; the forbidden-runtime scan returns no app-source/config matches.

- [ ] **Step 4: Open the project and visually verify**

Open `ios/FootballAgent.xcodeproj`; confirm scheme `FootballAgent`, destination `Charles’s 15 Pro Max`, and Ready status. Launch if the device is available, create a seeded game, advance one week, terminate/relaunch and confirm the save restores.

- [ ] **Step 5: Commit**

```bash
git add .gitignore Makefile README.md docs documentation ios
git commit -m "feat: ship offline native iPhone game"
```
