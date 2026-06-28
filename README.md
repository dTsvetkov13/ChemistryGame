# Chemistry Master (open dev branch)

A real-time multiplayer mobile game where players compete by building valid chemical reactions from element and compound cards. Reactions are validated live against the Wolfram Alpha API.

Players drag cards onto a reaction board (reactants → products), submit, and score points if the reaction is chemically correct. Supports both solo and team modes with push notifications, a friends/ranking system, and in-game chat.

## Architecture

```
Flutter app (iOS / Android)
        │
        │  Firebase SDK
        ▼
┌─────────────────────────────────────────┐
│  Firebase (chemistrygame-cd3a6)         │
│                                         │
│  Firestore   — game rooms, player       │
│               state, cards, chat        │
│  Auth        — email/password +         │
│               anonymous login           │
│  Messaging   — push notifications       │
│  Remote Config — in-game copy           │
│  Crashlytics — crash reporting          │
└──────────────┬──────────────────────────┘
               │
               ▼
   Cloud Functions (TypeScript / Node 8)
   eu-west-1, ~27 functions
               │
               ▼
        Wolfram Alpha API
        (reaction validation)
```

**Key directories**

```
App/chemistry_game/lib/
  screens/    — authenticate, home, loading, game screens
  models/     — Player, Card, Room, Reaction, User, …
  services/   — Firebase auth & Firestore wrappers
  classes/    — game logic (card drawing, utils)

CloudFunctions/functions/src/
  index.ts    — all Cloud Function exports (~27 functions)
```

## Running locally

**Prerequisites:** Flutter SDK, Node.js 8+, Firebase CLI, Android SDK or Xcode.

**Flutter app**

```bash
cd App/chemistry_game
flutter pub get
flutter run                 # connect a device or emulator first
```

**Cloud Functions**

```bash
cd CloudFunctions/functions
npm install
npm run build               # compile TypeScript
firebase emulators:start    # run locally against the emulator suite
```

To deploy functions to Firebase:

```bash
npm run deploy              # runs lint + build, then deploys
```

The app targets Android minSdk 21 / targetSdk 29 and iOS. Landscape-only orientation is enforced at runtime.
