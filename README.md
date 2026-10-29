# Senpeng

An iOS app that helps SL riders in Stockholm claim the delay money they are owed.

If an SL trip is 20+ minutes late, you can get money back, but you have to apply yourself on sl.se within 3 months. Senpeng saves the real delay when you tap "I'm on this train", reminds you before the deadline, and prepares everything the SL claim form asks for.

> Not affiliated with SL / Region Stockholm. Claims are submitted by the user on sl.se.

## Tech
Swift 6 · SwiftUI · MVVM · SwiftData · iOS 17+ (Liquid Glass on iOS 26)

## Getting started
1. Install Xcode 26 or later.
2. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and add your keys (optional for building).
3. Open `Senpeng.xcodeproj` and run the `Senpeng` scheme.
4. Optional: install SwiftLint (`brew install swiftlint`) and run `swiftlint --strict`.

## Contributing
- One feature = one branch = one pull request. Never commit directly to `main`.

## Data
Real-time data from [Trafiklab](https://www.trafiklab.se).
