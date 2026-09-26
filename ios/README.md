# iPhone build

Football Agent for iPhone is a self-contained SwiftUI app. It does not connect to the Python or Next.js game.

1. Open `FootballAgent.xcodeproj` in Xcode.
2. Select the **FootballAgent** scheme and your connected iPhone.
3. Press Run (`⌘R`).

Automatic signing is configured in `Config.xcconfig`. The app targets iOS 17+, works offline and autosaves after every successful action or week.

Run native tests with:

```bash
xcodebuild test -project FootballAgent.xcodeproj -scheme FootballAgent \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
