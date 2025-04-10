# BettorOdds: Tournament-Based Sports Betting

BettorOdds is a subscription-based sports betting application using tournament mechanics and virtual coins for an engaging, competitive experience.

## Features

- **Weekly Tournaments**: Compete for real cash prizes in weekly tournaments
- **Tournament Coins**: Receive 1,000 coins weekly to bet with
- **Leaderboards**: Track your performance against other players
- **Secure Authentication**: Sign in with Google or Apple
- **Real-Time Odds**: Up-to-date betting odds from major providers
- **Multi-Sport Support**: Bet on NBA, NFL, MLB and more
- **30-Day Free Trial**: Try all features before subscribing

## Architecture

BettorOdds is built with SwiftUI using an MVVM architecture and Firebase backend services:

- **Views**: SwiftUI interface components
- **ViewModels**: Business logic and state management
- **Models**: Core data structures
- **Repositories**: Data access layer
- **Services**: API and Firebase interactions

## Dependencies

- Firebase (Auth, Firestore, Functions)
- GoogleSignIn
- AuthenticationServices (Apple Sign-In)

## Development Workflow

1. Checkout development branch
2. Create feature branch
3. Implement feature
4. Add unit tests
5. Submit pull request
6. Code review
7. Merge to development

## Testing

Run tests with:
```swift
xcodebuild test -scheme BettorOdds -destination 'platform=iOS Simulator,name=iPhone 14'
