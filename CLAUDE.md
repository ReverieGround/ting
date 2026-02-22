# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

T!ng (VibeYum) is a Korean social food community mobile app built with React Native (Expo). Users share food experiences, recipes, and connect with others. The app uses Firebase for backend services (Authentication, Firestore, Storage) and Google Sign-In for authentication.

- **Bundle ID**: `com.reverieground.ting`
- **Firebase Project**: `vibeyum-alpha`
- **Branch**: `project/react-native-migration`

## Tech Stack

- Expo SDK 54, React 19.1, React Native 0.81.5
- TypeScript (strict mode)
- Expo Router v6 (file-based routing)
- Zustand (auth state management)
- React Query (server state / caching)
- React Native Firebase (`@react-native-firebase/*` v23.8.6)
- `@react-native-google-signin/google-signin` v16.1.1
- `@shopify/flash-list` for performant lists
- `expo-dev-client` (requires dev build, not Expo Go)

## Development Commands

```bash
# All commands run from ting-rn/ directory
# Requires Node 20 (see .nvmrc)
nvm use 20

# Install dependencies
npm install

# Start Metro dev server (requires dev build)
npx expo start --dev-client

# EAS build (development — iOS simulator)
npx eas build --platform ios --profile development

# EAS build (production — TestFlight)
npx eas build --platform ios --profile production

# Submit to TestFlight
npx eas submit --platform ios --latest

# Or use the deploy script
./deploy-testflight.sh
```

## Project Structure

```
ting-rn/
├── app/                          # Expo Router routes
│   ├── _layout.tsx               # Root layout (auth redirect, providers)
│   ├── index.tsx                 # Splash / loading spinner
│   ├── (auth)/
│   │   └── login.tsx             # Google Sign-In
│   ├── (onboarding)/
│   │   └── setup.tsx             # Profile setup (name, country, image)
│   └── (tabs)/
│       ├── _layout.tsx           # Tab bar (커뮤니티, 요리하기, 기록, 프로필)
│       ├── feed/                 # Feed list + post detail
│       ├── recipes/              # Recipe list, detail, edit
│       ├── create/               # Post creation + confirm
│       ├── profile/              # My profile + other user profile
│       └── users/                # Follower/following lists
├── src/
│   ├── components/               # Reusable UI components
│   │   ├── common/               # ProfileAvatar, Tag, TimeAgoText
│   │   ├── create/               # CategoryChips, ReviewChips, DatePicker, etc.
│   │   ├── feed/                 # FeedCard, Head, Content, FeedImages, StatIcons
│   │   └── profile/              # ProfileHeader, FollowButton, YumTab, GuestBookTab
│   ├── hooks/                    # Custom hooks (useAuth, useFeed, useFollow, useLike, etc.)
│   ├── services/                 # Firebase service layer
│   │   ├── authService.ts        # Auth, Google Sign-In, token management
│   │   ├── feedService.ts        # Feed queries (realtime, hot)
│   │   ├── postService.ts        # Post CRUD with visibility control
│   │   ├── userService.ts        # User profile management
│   │   ├── followService.ts      # Follow/unfollow
│   │   ├── recipeService.ts      # Recipe data from JSON asset
│   │   ├── storageService.ts     # Firebase Storage uploads
│   │   ├── guestBookService.ts   # Guest book / sticky notes
│   │   ├── profileService.ts     # Profile data fetching
│   │   └── gptService.ts         # OpenAI integration for recipe editing
│   ├── stores/
│   │   └── authStore.ts          # Zustand store (AppStatus state machine)
│   ├── theme/
│   │   └── colors.ts             # Color palette, spacing, radius constants
│   ├── types/                    # TypeScript interfaces (user, post, feed, recipe, guestbook)
│   └── utils/                    # Helpers (chunk, formatNumber, formatTimestamp, koreanGrammar)
├── assets/                       # App icons, splash image
├── plugins/
│   └── withFirebaseFixes.js      # Custom Expo config plugin for Firebase iOS build
├── app.config.ts                 # Expo config
├── eas.json                      # EAS Build profiles
├── GoogleService-Info.plist      # Firebase iOS config
└── deploy-testflight.sh          # TestFlight deploy script
```

## Architecture

### Auth State Machine (Zustand)
Managed in `src/stores/authStore.ts` with four states:
- `initializing` → App bootstrapping, checking Firebase auth
- `unauthenticated` → No user, show login
- `needsOnboarding` → Authenticated but missing profile (user_name / country_code)
- `authenticated` → Fully set up, show tabs

### Routing & Auth Redirect
Centralized in `app/_layout.tsx` using `useSegments()` + `useRouter()`:
- Watches `status` from authStore
- Redirects to `/(auth)/login`, `/(onboarding)/setup`, or `/(tabs)/feed` based on status
- Each tab subdirectory has its own `_layout.tsx` with a Stack navigator for nested routes

### Service Layer
All Firebase logic is in `src/services/`. Services interact directly with `@react-native-firebase/*` modules.

**Important**: RN Firebase `.exists` is a method `.exists()`, not a property (unlike web Firebase SDK).

### Theme
Dark mode focused. Colors defined in `src/theme/colors.ts`:
- Background: `#0F1115`
- Primary/text: `#EAECEF`
- Derived colors use `rgba()` with opacity helpers

## Firebase Integration

### Collections
- `users/` — user_id, user_name, country_code, country_name, bio, profile_image, provider, created_at
- `posts/` — user_id, title, content, image_urls, likes_count, comments_count, category, visibility, archived, created_at
- `follows/` — follower/following relationships
- `comments/`, `likes/`, `guest_notes/`

### Authentication
1. User taps Google Sign-In on login page
2. `authService.signInWithGoogle()` handles OAuth flow → Firebase credential
3. authStore `bootstrap()` checks Firestore user doc
4. Missing user_name/country_code → redirect to onboarding
5. Onboarding calls `authService.registerUser()` → creates Firestore doc
6. Status → `authenticated`

### Post Visibility
Three levels: `PUBLIC`, `FOLLOWER`, `PRIVATE`. Enforced in `postService.fetchUserPosts()` based on viewer relationship.

## Notes

- Recipe data loaded from static JSON asset, not Firestore
- Google Sign-In requires both `webClientId` (web type) and `iosClientId` (iOS type) in configuration
- No test coverage currently
- Korean UI text is hardcoded (no i18n system)
