# Football Agent

A football agent management game. You run an agency: scout talent on incomplete
information, sign clients, and take your cut of their moves.

The **Python simulation and Next.js game** explore agency building, client careers and transfer strategy. A separate native SwiftUI iPhone edition now carries the complete loop offline, with local saves and no Python, Node.js, WebKit or Mac-side server required while playing.

```
Scout on incomplete information
  -> sign clients by negotiating your cut
    -> manage their careers and their trust in you
      -> land deals in transfer windows for commission
        -> reinvest in scouts and premises
          -> press Continue
```

## Quick start

```bash
python3 -m pip install -r requirements.txt
python3 -m football_agent.cli.app --new --seed 42
```

Full instructions, including the tuning harness, are in
**[docs/how-to-run.md](docs/how-to-run.md)**.

## The three ideas the game rests on

**Scouting reports are ranges, never numbers.** "Ability 70–85, potential
unclear." The range narrows with your scout's quality, your agency's reputation
and how many scouts you have in that region — so growth buys *precision*, and
signing is always a bet.

**Negotiation is a bounded haggle with real risk.** Up to three rounds against a
hidden acceptance threshold that your reputation shifts in your favour. Their
counter-offer improves the longer you hold out, but irritation compounds, so
pushing late is where deals die. You get one negotiation per approach — naming a
number spends it, so a walk-away cannot be re-rolled.

**Playing time makes greed punishable.** It is derived from a client's ability
against his club's strength, and it drives development, trust and outside
interest. Park a client at a club too good for him because the wages were
better, and he rots, stops improving, and turns on you. Without this, moving
everyone to the richest club would always be correct and half the game's
decisions would evaporate.

The browser and native iPhone games also include agency departments, client careers, loans and a
[fictional stock exchange](documentation/features/investments.md) for investing
agency cash. Five original illustrations accompany the finance and progression UI.

For iPhone, open [`ios/FootballAgent.xcodeproj`](ios/FootballAgent.xcodeproj), choose a connected phone and press Run. The app is fully native and self-contained; see the [native iPhone guide](documentation/features/native-ios.md).

## Documentation

| Document | What it covers |
| --- | --- |
| [docs/how-to-run.md](docs/how-to-run.md) | Running the game, the tests and the tuning harness |
| [docs/v1-python-build-plan.md](docs/v1-python-build-plan.md) | The full design, the reasoning behind each decision, and what was deliberately deferred |
| [documentation/](documentation/README.md) | What was actually shipped: the web design system, the app shell, and the decisions model |
| [documentation/features/native-ios.md](documentation/features/native-ios.md) | Native iPhone architecture, gameplay scope, saves, tests and Xcode workflow |

## Agency expansion

The illustrated office now connects staff, departments, client stories, club relationships and loans. See [the expansion guide](documentation/features/agency-expansion.md) for mechanics, save migration and balance observations. Run `make dev` with the project virtual environment active to open the web game.

## Status

The expanded game is implemented and playable in the terminal, browser and native iPhone app. The Python/browser suite retains its design guards, while the Swift target adds native determinism, progression, transaction and save-recovery tests.

Deliberately **not** in v1: the Upgrades screen (properties and vehicles), multiple countries, continental competition, real squads with AI-to-AI
transfers, and split club/player reputation. Each is recorded in the build plan
with the reason.
