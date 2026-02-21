# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VibeYum (브랜드명: T!ng) is a Korean social food community Flutter application that allows users to share food experiences, recipes, and connect with others who share their love for food. The app uses Firebase for backend services (Authentication, Firestore, Storage) and supports multiple social login providers (Google, Facebook, Kakao, Naver).

## Development Commands

### Setup and Installation
```bash
# Install dependencies
flutter pub get

# Check available devices
flutter devices
```

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run with forced onboarding (for testing)
flutter run --dart-define=FORCE_ONBOARDING=true
```

### Building
```bash
# Build for Android
flutter build apk
flutter build appbundle  # For Play Store

# Build for iOS
flutter build ios

# Generate app icons
flutter pub run flutter_launcher_icons
```

### Code Generation
```bash
# Clean and rebuild
flutter clean
flutter pub get
```

## Architecture

### App State Machine
The app uses a custom state machine (`AppState` in `lib/main.dart`) to manage authentication and onboarding flow:
- `initializing`: App is bootstrapping and checking auth state
- `unauthenticated`: User needs to login
- `needsOnboarding`: User is authenticated but needs to complete profile setup
- `authenticated`: User is fully authenticated and onboarded

### Routing
Uses `go_router` (v16.2.1) with state-based redirection. Routes are defined in `buildRouter()` in `lib/main.dart`:
- `/splash`: Initial loading screen
- `/login`: Authentication page with social login options
- `/onboarding`: Profile setup for new users
- `/home`: Main app (feed, profile, recipe browsing)

The router listens to `AppState` changes and automatically redirects users based on their authentication status.

### Service Layer Pattern
All Firebase and business logic is isolated in service classes (`lib/services/`):

- **AuthService**: Manages Firebase Auth, social login (Google, Facebook, Kakao, Naver), token storage via FlutterSecureStorage
- **FeedService**: Fetches posts for the feed (realtime and hot feeds)
- **PostService**: CRUD operations for posts with visibility control (PUBLIC, FOLLOWER, PRIVATE)
- **UserService**: User profile management and updates
- **FollowService**: Follow/unfollow relationships
- **RecipeService**: Loads and searches recipes from JSON asset
- **StorageService**: Firebase Storage uploads (images)
- **ProfileService**: User profile data fetching
- **GuestBookService**: Guest book/message board features

### Data Models (`lib/models/`)
Key models with Firebase Firestore integration:
- **PostData**: User posts with visibility, archiving, categories
- **FeedData**: Composite model combining PostData + UserData + engagement metrics (likes, comments). Uses async factory pattern (`FeedData.create()`)
- **UserData**: User profiles with country info, bio, profile images
- **Recipe**: Recipe data loaded from `assets/recipe_dict_filtered.json`
- **ProfileInfo/ProfileData**: User profile views and metadata

### UI Structure
```
lib/
├── main.dart              # Entry point, AppState, routing
├── home/HomePage.dart     # Bottom nav with FAB (Feed, Profile, Recipes)
├── feeds/                 # Feed/timeline UI
│   └── widgets/           # Feed card components (Head, Content, Images, Tags, Icons)
├── profile/               # User profile pages
│   └── widgets/           # Profile components (Header, FollowButton)
├── posts/                 # Individual post detail pages
├── create/                # Post creation flow
├── recipe/                # Recipe browsing and detail pages
├── users/                 # User-related pages
├── nearby/                # Location-based feed (未使用?)
├── login/                 # Authentication pages
├── onboarding/            # New user setup
└── theme/AppTheme.dart    # Centralized theme (dark mode focused)
```

### Theme System
Centralized theme in `lib/theme/AppTheme.dart`:
- Currently uses light theme forced mode (dark color scheme with light brightness setting)
- Primary color: `#EAECEF` (off-white)
- Background: `#0F1115` (dark)
- Uses `ColorScheme.fromSeed()` for consistent color derivation

## Firebase Integration

### Collections Structure
- `users/`: User profiles (user_id, user_name, country_code, bio, profile_image, provider, created_at)
- `posts/`: User posts (user_id, title, content, image_urls, likes_count, comments_count, category, visibility, archived, created_at)
- `follows/`: Follow relationships
- Additional collections: comments, likes, recipes (referenced but not detailed in codebase)

### Authentication Flow
1. User selects social login provider on LoginPage
2. AuthService handles OAuth flow and creates Firebase user
3. AppState checks if user document exists in Firestore
4. If missing user_name or country_code, redirect to OnboardingPage
5. OnboardingPage calls `AuthService.registerUser()` to create user document
6. AppState transitions to `authenticated` status

### Token Management
- Firebase ID tokens stored in FlutterSecureStorage (key: `auth_token`)
- Tokens refreshed and validated via `saveIdToken()` and `verifyStoredIdToken()`
- Login history tracked via `has_logged_in_before` flag

## Key Technical Details

### Post Visibility System
Posts have three visibility levels enforced in `PostService.fetchUserPosts()`:
- `PUBLIC`: Visible to everyone
- `FOLLOWER`: Visible to followers only
- `PRIVATE`: Visible to post owner only

The service checks viewer's relationship (owner/follower) and filters posts via Firestore `whereIn` query.

### Image Handling
- Image uploads via `StorageService` to Firebase Storage
- Local caching with `cached_network_image` package
- Image cropping with `image_cropper` before upload
- EXIF data handling for proper orientation

### Korean Localization
- App supports Korean (ko) and English (en) locales
- Uses `flutter_localizations` for Material/Cupertino widgets
- Most UI text is hardcoded in Korean (not using intl l10n system)

### Platform-Specific Code
- Desktop platforms (Windows, Linux, macOS) use `sqflite_common_ffi` for local database
- iOS uses Kakao SDK and Naver Login native integration
- Biometric auth via `local_auth` for faster re-login

## Common Patterns

### Async Data Loading
Most services return `Future<List<Model>>` or `Future<Model?>`. UI widgets should use `FutureBuilder` or state management to handle loading states.

### Error Handling
Services use `debugPrint()` for errors and typically return `null` or empty lists on failure. Consider adding proper error propagation for production.

### State Management
Currently uses basic `StatefulWidget` with `setState()`. No dedicated state management library (Provider, Riverpod, Bloc). The `PageStorageBucket` is used in HomePage to preserve scroll positions across tab switches.

## Notes for Development

- Recipe data is loaded from static JSON asset (`assets/recipe_dict_filtered.json`), not from Firestore
- Some features reference unused pages (e.g., `nearby/NearbyPage.dart`)
- Social login for Kakao/Naver requires backend to exchange tokens for Firebase Custom Tokens (not implemented in this codebase)
- Assets directory is gitignored - ensure assets exist locally before running
- No test directory or test coverage currently in the project
