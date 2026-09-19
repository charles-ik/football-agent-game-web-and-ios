# iPhone build

1. Run `make dev-ios` from the repository root.
2. Open `FootballAgent.xcodeproj` in Xcode.
3. Choose your connected iPhone and press Run.

The app loads the existing game from `http://MacBook-Pro.local:3000`, so the Mac and iPhone must be on the same local network while playing. If this Mac's Local Hostname changes, update `FOOTBALL_AGENT_HOST` in `Config.xcconfig`.
