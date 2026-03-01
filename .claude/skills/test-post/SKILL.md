---
name: test-post
description: Verify post creation, visibility control, management, and image handling
argument-hint: [focus-area]
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
---

# Post System Test Agent

You are a test agent responsible for verifying the **post creation, visibility, management, and image handling** features of the T!ng app.

## Scope

Your testing domain covers:

### 1. Post Creation Flow
- **Create page** (`app/(tabs)/create/index.tsx`):
  - Image selection via `expo-image-picker` (max 10)
  - `DatePickerButton` (default: today)
  - `CategoryChips` — 요리/밀키트/식당/배달
  - `ReviewChips` — Fire/Tasty/Soso/Woops/Wack
  - `PostTextField` — multiline text input
  - Conditional fields per category (recipe toggle, link input, restaurant name)
- **Confirm page** (`app/(tabs)/create/confirm.tsx`):
  - Image stack preview with rotation effect
  - Category, review, image count, content preview
  - Visibility selector (PUBLIC/FOLLOWER/PRIVATE)
  - Upload button → image upload → post creation

### 2. Create Components (`src/components/create/`)
- `CategoryChips` — selected + onSelect props
- `ReviewChips` — selected + onSelect props
- `PostTextField` — value + onChangeText props
- `LinkInputRow` — value + onChangeText + placeholder + icon props
- `DatePickerButton` — date + onDateChange props (iOS modal, Android native)

### 3. Post Service (`src/services/postService.ts`)
- `createPost(input)` — Firestore document creation
- `updateFields(postId, fields)` — partial field update
- `softDelete(postId)` — set archived: true (not hard delete)
- `toggleLike(postId, userId)` — Transaction-based atomic toggle

### 4. Visibility Filtering
- `fetchUserPosts(userId, viewerId)`:
  - owner: PUBLIC + FOLLOWER + PRIVATE
  - follower: PUBLIC + FOLLOWER
  - visitor: PUBLIC only
  - Uses Firestore `whereIn` query

### 5. Pin Management
- `pinPost(postId)` / `unpinPost(postId)` / `togglePin(postId)`
- `fetchPinnedPosts(userId)` — ordered by pin_order
- YumTab long-press triggers pin toggle

### 6. Image Handling (`src/services/storageService.ts`)
- `uploadPostImage(postId, uri, index)` — single image with metadata
- `uploadPostImages(postId, uris)` — parallel via `Promise.all`
- `deleteByUrl(url)` — URL-based Storage file deletion
- Storage paths: `posts/{postId}/{uuid}.{ext}`

## Test Instructions

1. Read the relevant source files
2. Verify post creation components match `docs/FE_ARCH.md` Section 6.3
3. Verify postService functions match `docs/BE_ARCH.md` Section 4.3
4. Check visibility filtering logic handles all 3 viewer types correctly
5. Verify image upload uses parallel processing (`Promise.all`)
6. Confirm soft delete sets `archived: true` (not actual document deletion)
7. Report any discrepancies between code and documentation

If `$ARGUMENTS` is provided, focus testing on that specific area.
