# Native iPhone Game Design

**Date:** 2026-09-26  
**Status:** Approved for implementation by the user's instruction to include everything and continue without questions.

## Outcome

Football Agent becomes a self-contained iPhone game written in Swift and SwiftUI. The installed app must launch, create and load games, simulate weeks, perform every player action and save progress without WebKit, HTTP, Python, Node.js or a Mac-side process.

The existing Python engine and web UI remain in the repository as the tuning reference and regression oracle. They are not linked, embedded, invoked or contacted by the iPhone target.

## Product scope

The native game includes every currently shipped system:

- seeded new games, multiple save slots and game over;
- weekly calendar, seasons, transfer windows and advance-to-next-event;
- scouting regions, scout assignments, briefs, focused reports and hidden ranges;
- client approaches and bounded commission negotiations;
- clients, trust, playing time, development, injuries and representation renewals;
- club approaches, transfer negotiations, renewals and commission;
- club relationships, pitches, loan talks, active loans and returns;
- career goals, promises, conversations, histories and alumni;
- rival agencies, prospect signings, poaching warnings and departures;
- support staff, portfolios, departments, identity and specialization;
- seasonal objectives, reviews and agency milestones;
- headquarters, capacity, weekly finances, insolvency and forced downsizing;
- fictional stocks, deterministic weekly prices, holdings, fees and gains;
- leagues, club directory and season rollover.

The five editorial images, agency icon and established green/gold visual character are bundled into the app and reused.

## Architecture

### Game engine module

`GameEngine` is the deep module. Its interface is deliberately small:

```swift
enum GameEngine {
    static func newGame(name: String, seed: UInt64) -> GameState
    static func perform(_ action: GameAction, on state: inout GameState) -> ActionOutcome
    static func advance(_ mode: AdvanceMode, state: inout GameState) -> [GameEvent]
    static func decisions(in state: GameState) -> [GameDecision]
}
```

All rules, validation, hidden information, deterministic randomness and weekly system ordering stay behind that interface. Refusals are `ActionOutcome` values rather than thrown errors because unaffordable or unavailable actions are ordinary play.

State is plain `Codable`, `Equatable`, `Sendable` Swift data. Views never mutate it directly and never calculate rules. True ability, potential and negotiation thresholds remain inside the engine model; views receive report ranges and qualitative assessments.

### Determinism

A small native SplitMix64 generator derives independent streams from game seed, week and system name. Scouting, leagues, stocks, careers and rivals cannot reroll one another. The seed and state are saved, so reopening the app cannot reroll an outcome.

### Persistence

`GameStore` is the sole app-facing model. It owns the selected save, calls `GameEngine`, publishes outcomes and atomically writes JSON under Application Support after every successful action and week. A `.bak` copy is retained before replacement. Invalid or newer save schemas produce a recoverable load error and never overwrite the source file.

Save schema starts at native version 1. The web/Python save format is not imported because its untyped expansion dictionaries would make the native model brittle; both games can still recreate the same authored world from a seed.

### Content

The current club, region, name and balance JSON files are copied into the app bundle and decoded into typed Swift structures. The native target owns its runtime copies. Adding a club or tuning a number remains a data edit, not a view change.

### SwiftUI application

The app uses native `TabView`, `NavigationStack`, `List`, `Form`, `Sheet`, `ConfirmationDialog`, `ProgressView` and Swift Charts. No web view or browser-style route layer remains.

Primary tabs are:

1. **Office** — current pressure, guided next move, progression, decisions and recent events.
2. **Clients** — roster and native client dossiers.
3. **Scouting** — scouts, regions, reports and approaches.
4. **Market** — club interest, pitches, loans and club directory.
5. **More** — Agency, Finances, Stocks, World, Headquarters, Season Review and save controls.

A safe-area Continue bar is available from every game screen. Negotiations and conversations use native sheets. Destructive actions use confirmation dialogs. Dynamic Type, VoiceOver labels, 44pt controls, reduced motion and portrait safe areas are required.

## Flow and progression improvements

The rewrite keeps the existing rules but improves how the first ten seasons are paced and explained.

### Guided opening

The Office always presents one evidence-based “Next move.” A first-agency checklist leads through assigning the scout, advancing for a report, shortlisting, signing and pursuing the first deal. It is state-derived, dismisses itself naturally and never blocks free play with tutorial modals.

### Progressive disclosure

All systems ship in the app, but secondary systems unlock at meaningful achievements:

- the core office, clients, scouting, finances and headquarters start open;
- Market and club relationships open with the first additional client;
- support staff, departments, specialization and loans open after the first commission;
- Stocks open when the agency has both a positive recurring budget and £100,000 cash.

Locked destinations remain visible with the exact requirement. This reduces first-week overload without hiding the game's breadth.

### Clearer pressure

Open decisions are derived from current state, ordered by severity and deadline, and disappear when resolved. The Continue bar shows the unresolved count and warns before skipping an actionable deadline. “Advance to next event” stops after at most 12 weeks, at a decision, transfer-window boundary, warning or major milestone.

### Stronger progression feedback

Agency standing has named stages—Startup, Established, Contender and Elite—with a visible next threshold. Milestones award a small, explicit combination of cash, reputation or scouting precision instead of acting only as historical stamps. Seasonal objectives show target, progress and reward everywhere they matter.

The target arc remains roughly eight to ten seasons from nobody to elite. The first useful report should usually arrive within four weeks, the first viable signing within eight, and the starting runway must survive a cautious first season.

### Better outcomes

Every action returns a concise result explaining what changed and why. Client dossiers show a chronological career story. Weekly events collapse repeated bookkeeping into one summary while preserving major outcomes. Finance separates spendable cash, recurring operations, football commission and investments.

## Weekly simulation order

One Continue executes this stable order:

1. settle retainers, payroll, departments, headquarters and region costs;
2. move stock prices;
3. advance injuries, age/development and contracts;
4. update playing time, trust, goals and promises;
5. process scouts and narrow reports;
6. expire offers and loans, then generate transfers, renewals and loan interest;
7. let rivals sign prospects or progress poaching warnings;
8. simulate league results;
9. evaluate objectives, milestones, unlocks, solvency and game over;
10. derive decisions and append player-facing events.

Each system receives its own deterministic random stream.

## Error handling

- Invalid actions leave `GameState` unchanged and return a readable refusal.
- Successful actions autosave before their success presentation is dismissed.
- Save failures preserve the in-memory game, retain the previous disk file and show a persistent recovery message.
- Missing bundled content is a development assertion and falls back to compiled starter content in release builds.
- Empty lists have explicit native empty states; unavailable controls explain their requirement.

## Verification

The project gains an XCTest target testing through the `GameEngine` interface:

- deterministic creation and weekly advancement;
- report uncertainty narrowing without hidden-value leakage;
- bounded negotiations and non-trivial walk-away risk;
- transfer, loan and commission accounting;
- trust, career, rival and contract outcomes;
- progression unlocks, objectives and milestone rewards;
- stock fees, holdings and deterministic prices;
- insolvency, downsizing and game over;
- JSON save round trips and corrupt-save recovery.

The finished app must pass the native tests, build with automatic signing for the connected iPhone, contain no `WebKit` import or network entitlement, launch without a server, create a game, advance a week and restore the save after relaunch.

## Explicit exclusions

No real football data, online accounts, multiplayer, cloud saves, notifications, in-app purchases or full squad simulation are introduced. These would add unrelated systems without improving the requested offline native port.
