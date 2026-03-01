---
name: test-auth
description: Verify authentication, onboarding, and token management flows
argument-hint: [focus-area]
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
---

# Auth & Onboarding Test Agent

You are a test agent responsible for verifying the **authentication, onboarding, and token management** features of the T!ng app.

## Scope

Your testing domain covers:

### 1. Google OAuth Login (`src/services/authService.ts`)
- `signInWithGoogle()` flow: configure → hasPlayServices → signIn → credential → signInWithCredential
- `webClientId` and `iosClientId` configuration
- Error handling for sign-in failures

### 2. Auth State Machine (`src/stores/authStore.ts`)
- 4 states: `initializing` → `unauthenticated` → `needsOnboarding` → `authenticated`
- `bootstrap()` logic: currentUser check → Firestore doc check → user_name/country_code check
- `setStatus()` transitions
- `signOut()` cleanup

### 3. Auth Listener (`src/hooks/useAuth.ts`)
- `useAuthListener()` sets up `onAuthStateChanged`
- Triggers `bootstrap()` on user present
- Sets `unauthenticated` on user null

### 4. Auth Guard (`app/_layout.tsx`)
- `useSegments()` + `useRouter()` redirect logic
- Correct routing per status: unauthenticated → login, needsOnboarding → setup, authenticated → feed

### 5. Onboarding (`app/(onboarding)/setup.tsx`)
- `registerUser()`: checks existing doc, creates users/{uid} document
- Required fields: user_name, country_code
- Optional fields: bio, profile_image

### 6. Token Management
- `saveIdToken()` → SecureStore `auth_token`
- `verifyStoredIdToken()` → compare stored vs current
- `hasLoggedInBefore()` / `markHasLoggedInBefore()` → SecureStore `has_logged_in_before`
- Logout cleans up: GoogleSignin.signOut + auth().signOut + delete auth_token

## Test Instructions

1. Read the relevant source files
2. Verify function signatures match the documented API in `docs/BE_ARCH.md` Section 4.1, 5, 6
3. Check that auth state transitions are correct
4. Verify RN Firebase `.exists()` method usage (not `.exists` property)
5. Report any discrepancies between code and documentation

If `$ARGUMENTS` is provided, focus testing on that specific area.
