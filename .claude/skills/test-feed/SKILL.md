---
name: test-feed
description: Verify feed system, post detail page, and real-time comments
argument-hint: [feed-type]
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
---

# Feed System Test Agent

You are a test agent responsible for verifying the **feed system, post detail, and comments** features of the T!ng app.

## Scope

Your testing domain covers:

### 1. Feed Service (`src/services/feedService.ts`)
- `fetchRealtimeFeeds()` — PUBLIC posts, ordered by created_at DESC
- `fetchHotFeeds()` — PUBLIC posts, ordered by likes_count DESC
- `fetchWackFeeds()` — value='Wack' posts, ordered by likes_count DESC
- `fetchPersonalFeed()` — following users' posts, excluding blocked users
- `buildFeedData()` helper — parallel fetch of user + like status + pin status

### 2. chunk() Handling (`src/utils/chunk.ts`)
- Personal feed uses `chunk(10)` to split following UIDs
- Parallel `whereIn` queries per chunk
- Results merged and sorted

### 3. Feed Hooks (`src/hooks/useFeed.ts`)
- `useRealtimeFeed()` — query key `['feed', 'realtime']`
- `useHotFeed()` — query key `['feed', 'hot']`
- `useWackFeed()` — query key `['feed', 'wack']`
- `usePersonalFeed()` — query key `['feed', 'personal']`
- React Query staleTime: 5 minutes, retry: 2

### 4. Feed Components (`src/components/feed/`)
- `FeedCard` — composition of Head + FeedImages + StatIcons + Content
- `Head` — avatar, userName, timeAgo, menu (isMine → edit options)
- `FeedImages` — image carousel with pagination + category/value tag overlay
- `StatIcons` — like/comment icons with counts, like toggle integration
- `Content` — post body text
- `CommentTile` — individual comment display with delete for own comments

### 5. Post Detail (`app/(tabs)/feed/[postId].tsx`)
- Full FeedCard display
- Real-time comment subscription via `useComments`
- Comment input bar with `KeyboardAvoidingView`
- Own comment deletion

### 6. Comments (`src/hooks/useComments.ts`)
- `useFirestoreQuery` for real-time comment list
- `addComment(content)`, `editComment(id, text)`, `deleteComment(id)`
- `postService.commentsStream(postId)` returns ordered query

## Test Instructions

1. Read the relevant source files
2. Verify feed service functions match `docs/BE_ARCH.md` Section 4.2
3. Verify component props match `docs/FE_ARCH.md` Section 6.1
4. Check `chunk()` implementation handles edge cases (0 followers, exactly 10, >10)
5. Verify React Query hook configurations
6. Report any discrepancies between code and documentation

If `$ARGUMENTS` is provided (e.g., "realtime", "hot", "personal"), focus on that feed type.
