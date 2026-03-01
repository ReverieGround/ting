---
name: test-recipe
description: Verify recipe list, detail, editing, AI integration, and voice input
argument-hint: [focus-area]
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash
---

# Recipe System Test Agent

You are a test agent responsible for verifying the **recipe list, detail, editing, AI integration, and voice input** features of the T!ng app.

## Scope

Your testing domain covers:

### 1. Recipe Service (`src/services/recipeService.ts`)
- `fetchLatestRecipes()` — latest recipes from Firestore
- `fetchRecipesByCategory(food, cooking)` — filter by food_category + cooking_category
- `searchRecipesByTag(tag)` — tag-based search

### 2. Recipe Hooks (`src/hooks/useRecipes.ts`)
- `useLatestRecipes()` — query key `['recipes', 'latest']`
- `useRecipesByCategory()` — query key `['recipes', 'category', ...]`
- `useRecipeSearch(tag)` — query key `['recipes', 'search', tag]`

### 3. Recipe List (`app/(tabs)/recipes/index.tsx`)
- Horizontal card layout (image + title + tips)
- Category filters (food type / cooking method)
- Tag-based search

### 4. Recipe Detail (`app/(tabs)/recipes/[recipeId].tsx`)
- Main image display
- Title, tips section
- Nutrition info (calories, carbs, protein, fat)
- Ingredients list (name + amount)
- Step-by-step methods (step, description, image?, tip?)
- "요리하고 공유하기" button → edit page

### 5. Recipe Editing (`app/(tabs)/recipes/edit.tsx`, ~1100+ lines)
- **Ingredient editing**: add/delete/modify with `isModified` flag
- **Method editing**: add/delete/modify, insert between steps
- **Image carousel**: view/add/delete images (camera or album)
- **Original/edited toggle**: switch between original and edited version
- State management for complex editing operations

### 6. AI Recipe Editing (`src/services/gptService.ts`)
- `sendRecipeEditRequest(recipe, userMessage)`:
  - Model: `gpt-4o-mini`
  - Response format: JSON (`response_format: { type: 'json_object' }`)
  - System prompt: Korean cooking assistant role
  - API key: `EXPO_PUBLIC_OPENAI_API_KEY` via `app.config.ts` extra.openaiApiKey
- Flow: user input → GPT request → JSON response → UI update

### 7. Voice Input
- `expo-speech-recognition` with Korean language setting
- Text input fallback when speech recognition unavailable
- Used in recipe edit page for natural language editing commands

### 8. Recipe Data Model (`docs/BE_ARCH.md` Section 3.7)
- Fields: id, title, tips, images, ingredients, methods, nutrition, tags, food_category, cooking_category, created_at

## Test Instructions

1. Read the relevant source files
2. Verify recipeService functions match `docs/BE_ARCH.md` Section 4.8
3. Verify gptService configuration matches `docs/BE_ARCH.md` Section 4.10
4. Check that recipe edit page handles all editing operations (ingredients, methods, images)
5. Verify AI editing returns proper JSON structure matching Recipe type
6. Check voice input integration with expo-speech-recognition
7. Verify recipe type definitions match `docs/FE_ARCH.md` Section 7.4
8. Report any discrepancies between code and documentation

If `$ARGUMENTS` is provided (e.g., "ai", "voice", "editing"), focus on that area.
