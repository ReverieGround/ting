# 데이터 모델 및 스키마

## 모델 관계도

```
                    ┌────────────┐
                    │  UserData  │
                    │ (기본 정보) │
                    └─────┬──────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼─────┐   ┌────▼─────┐   ┌─────▼──────┐
    │ ProfileInfo│   │ FeedData │   │StickyNote  │
    │ (상세 통계) │   │ (복합)   │   │Model       │
    └─────┬─────┘   └────┬─────┘   └────────────┘
          │               │
    ┌─────▼──────┐   ┌───▼──────┐
    │ProfileData │   │ PostData │
    │(Info+Posts) │   │ (포스트) │
    └────────────┘   └──────────┘

    ┌───────────┐   ┌──────────────┐
    │  Recipe    │   │PostInputData │
    │(레시피)    │   │(작성 입력)   │
    └───────────┘   └──────────────┘
```

---

## Dart 모델 클래스 상세

### PostData (`lib/models/PostData.dart`)

Firestore `posts` 컬렉션의 문서를 표현합니다.

```dart
class PostData {
  final String userId;
  final String postId;
  final String title;
  final String content;
  final List<dynamic>? comments;
  final List<dynamic>? imageUrls;
  final int likesCount;
  final int commentsCount;
  final String category;
  final String? value;
  final String? recipeId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String visibility;
  final bool archived;
}
```

| 필드 | 타입 | Firestore 키 | 설명 |
|------|------|-------------|------|
| `userId` | `String` | `user_id` | 작성자 UID |
| `postId` | `String` | `post_id` | 포스트 ID |
| `title` | `String` | `title` | 제목 |
| `content` | `String` | `content` | 본문 |
| `comments` | `List<dynamic>?` | `comments` | (레거시, 서브컬렉션으로 대체) |
| `imageUrls` | `List<dynamic>?` | `image_urls` | 이미지 URL 배열 |
| `likesCount` | `int` | `likes_count` | 좋아요 수 (캐시) |
| `commentsCount` | `int` | `comments_count` | 댓글 수 (캐시) |
| `category` | `String` | `category` | 카테고리 (요리/밀키트/식당/배달) |
| `value` | `String?` | `value` | 리뷰 값 (Fire/Tasty/Soso/Woops/Wack) |
| `recipeId` | `String?` | `recipe_id` | 연결된 레시피 ID |
| `createdAt` | `Timestamp` | `created_at` | 생성 시각 |
| `updatedAt` | `Timestamp` | `updated_at` | 수정 시각 |
| `visibility` | `String` | `visibility` | 공개범위 (PUBLIC/FOLLOWER/PRIVATE) |
| `archived` | `bool` | `archived` | 소프트 삭제 여부 |

**직렬화**: `PostData.fromMap(Map<String, dynamic>)` 팩토리 생성자로 Firestore 문서 → 객체 변환.

---

### FeedData (`lib/models/FeedData.dart`)

포스트 + 사용자 + 인터랙션 메트릭스를 결합한 복합 모델입니다.

```dart
class FeedData {
  final UserData user;
  final PostData post;
  final bool isPinned;
  final bool isLikedByUser;
  final int numComments;
  final int numLikes;
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `user` | `UserData` | 포스트 작성자 정보 |
| `post` | `PostData` | 포스트 데이터 |
| `isPinned` | `bool` | 현재 사용자가 핀했는지 |
| `isLikedByUser` | `bool` | 현재 사용자가 좋아요했는지 |
| `numComments` | `int` | 댓글 수 (실시간) |
| `numLikes` | `int` | 좋아요 수 (실시간) |

**생성 패턴**: 비동기 팩토리 `FeedData.create()` 사용

```dart
static Future<FeedData> create({
  required PostData post,
  UserData? user,        // null이면 Firestore에서 조회
  bool? isPinned,        // null이면 pinned_posts 서브컬렉션 조회
  bool? isLikedByUser,   // null이면 likes 서브컬렉션 조회
  int? numComments,      // null이면 comments count 조회
  int? numLikes,         // null이면 likes count 조회
}) async { ... }
```

`create()`는 누락된 데이터를 병렬로 Firestore에서 조회합니다:
1. `user` → `users/{post.userId}` 문서 조회
2. `isPinned` → `users/{currentUser}/pinned_posts/{postId}` 존재 확인
3. `numLikes` → `posts/{postId}/likes` count 집계
4. `isLikedByUser` → `posts/{postId}/likes/{currentUser}` 존재 확인
5. `numComments` → `posts/{postId}/comments` count 집계

---

### UserData (`lib/models/UserData.dart`)

사용자 기본 정보를 표현하는 경량 모델입니다.

```dart
class UserData {
  final String userId;
  final String userName;
  final String location;
  final String title;
  final String? statusMessage;
  final String? profileImage;
}
```

| 필드 | 타입 | Firestore 키 | 기본값 |
|------|------|-------------|--------|
| `userId` | `String` | `user_id` | `''` |
| `userName` | `String` | `user_name` | `''` |
| `location` | `String` | `location` | `'Seoul'` |
| `title` | `String` | `user_title` | `''` |
| `statusMessage` | `String?` | `status_message` | `''` |
| `profileImage` | `String?` | `profile_image` | `''` |

**메서드**: `fromJson()`, `toJson()`, `copyWith()`

---

### ProfileInfo (`lib/models/ProfileInfo.dart`)

프로필 페이지에서 사용하는 상세 통계 포함 모델입니다.

```dart
class ProfileInfo {
  final String userId;
  final String userName;
  final String location;
  final int recipeCount;
  final int postCount;
  final int receivedLikeCount;
  final int followerCount;
  final int followingCount;
  final String? profileImage;
  final String? statusMessage;
  final String userTitle;
}
```

| 필드 | 타입 | Firestore 키 | 기본값 |
|------|------|-------------|--------|
| `userId` | `String` | `user_id` | `''` |
| `userName` | `String` | `user_name` | `''` |
| `location` | `String` | `location` | `'서울시'` |
| `recipeCount` | `int` | `recipe_count` | `0` |
| `postCount` | `int` | `post_count` | `0` |
| `receivedLikeCount` | `int` | `received_like_count` | `0` |
| `followerCount` | `int` | `follower_count` | `0` |
| `followingCount` | `int` | `following_count` | `0` |
| `profileImage` | `String?` | `profile_image` | `''` |
| `statusMessage` | `String?` | `status_message` | `''` |
| `userTitle` | `String` | `user_title` | `''` |

**메서드**: `fromJson()`, `toJson()`, `copyWith()`, `empty()` (팩토리)

> `postCount`, `followerCount`, `followingCount` 등은 Firestore 문서 자체에 저장되지 않고, `UserService.fetchUserForViewer()`에서 서브컬렉션 count 집계 후 동적으로 주입됩니다.

---

### ProfileData (`lib/models/ProfileData.dart`)

ProfileInfo + 포스트 목록 + 핀 포스트를 묶은 컨테이너 모델입니다.

```dart
class ProfileData {
  final ProfileInfo profileInfo;
  final List<PostData> posts;
  final List<PostData> pinned;
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `profileInfo` | `ProfileInfo` | 프로필 상세 정보 + 통계 |
| `posts` | `List<PostData>` | 사용자의 포스트 목록 |
| `pinned` | `List<PostData>` | 핀된 포스트 목록 |

---

### Recipe (`lib/models/Recipe.dart`)

레시피 데이터를 표현합니다. 하위 모델 클래스를 포함합니다.

```dart
class Recipe {
  final String id;
  final String title;
  final String foodCategory;
  final String cookingCategory;
  final Images images;
  final String tags;
  final String tips;
  final List<Ingredient> ingredients;
  final List<Method> methods;
  final Nutrition nutrition;
}
```

#### 하위 모델: Images

```dart
class Images {
  final String originalUrl;
  final String localPath;
}
```

#### 하위 모델: Ingredient

```dart
class Ingredient {
  final String name;
  final String quantity;
}
```

#### 하위 모델: Method

```dart
class Method {
  final String describe;
  final MethodImage image;
}

class MethodImage {
  final String originalUrl;
  final String localPath;
}
```

#### 하위 모델: Nutrition

```dart
class Nutrition {
  final String calories;
  final String protein;
  final String carbohydrates;
  final String fat;
  final String sodium;
}
```

**직렬화**: 모든 하위 모델에 `fromJson()` 및 `toJson()` 구현.

---

### PostInputData (`lib/models/PostInputData.dart`)

포스트 작성 시 이미지당 하나의 입력 폼 데이터를 표현합니다.

```dart
class PostInputData {
  List<File> imageFiles;
  String selectedValue = "";
  String selectedCategory = "";
  String capturedDate;
  bool recommendRecipe = false;
  String mealKitLink = "";
  String restaurantLink = "";
  String deliveryLink = "";
  TextEditingController textController;
  String get content => textController.text;
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `imageFiles` | `List<File>` | 선택된 이미지 파일 |
| `selectedValue` | `String` | 리뷰 값 (Fire/Tasty/...) |
| `selectedCategory` | `String` | 카테고리 (요리/밀키트/...) |
| `capturedDate` | `String` | 촬영 일시 (포맷: yyyy. MM. dd HH:mm) |
| `recommendRecipe` | `bool` | 레시피 추천 여부 |
| `mealKitLink` | `String` | 밀키트 구매 링크 |
| `restaurantLink` | `String` | 식당 링크 |
| `deliveryLink` | `String` | 배달 링크 |
| `textController` | `TextEditingController` | 본문 텍스트 컨트롤러 |

> 이 모델은 Firestore에 직접 저장되지 않으며, `ConfirmPage`에서 `PostService.createPost()`로 변환됩니다.

---

### StickyNoteModel (`lib/models/StickyNoteModel.dart`)

게스트북 스티키 노트를 표현합니다.

```dart
class StickyNoteModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final DateTime createdAt;
  final bool pinned;
  final String text;
  final Color color;
}
```

| 필드 | 타입 | Firestore 키 | 설명 |
|------|------|-------------|------|
| `id` | `String` | `id` | 노트 ID |
| `authorId` | `String` | `authorId` | 작성자 UID |
| `authorName` | `String` | `authorName` | 작성자 이름 |
| `authorAvatarUrl` | `String` | `authorAvatarUrl` | 작성자 아바타 URL |
| `createdAt` | `DateTime` | `createdAt` (Timestamp) | 생성 시각 |
| `pinned` | `bool` | `pinned` | 핀 여부 |
| `text` | `String` | `text` | 노트 내용 (최대 20자) |
| `color` | `Color` | `color` (int) | 노트 배경색 (Color.value) |

**메서드**: `copyWith({text, color, pinned})`

---

## Firestore 문서 스키마

### users/{userId}

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `user_id` | string | O | Firebase Auth UID |
| `email` | string | O | 이메일 |
| `user_name` | string | O | 닉네임 |
| `profile_image` | string | - | 프로필 이미지 URL |
| `bio` | string | - | 자기소개 |
| `country_code` | string | O | 국가 코드 (KR, US, JP) |
| `country_name` | string | O | 국가명 |
| `location` | string | - | 지역 |
| `user_title` | string | - | 칭호 |
| `status_message` | string | - | 상태 메시지 |
| `provider` | string | O | 로그인 프로바이더 |
| `created_at` | Timestamp | O | 가입 시각 (서버) |

### posts/{postId}

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `post_id` | string | O | 문서 ID |
| `user_id` | string | O | 작성자 UID |
| `title` | string | O | 제목 |
| `content` | string | O | 본문 |
| `image_urls` | array\<string\> | O | 이미지 URL 목록 |
| `category` | string | O | 카테고리 |
| `value` | string | O | 리뷰 값 |
| `visibility` | string | O | 공개범위 |
| `archived` | bool | O | 삭제 여부 |
| `recipe_id` | string | - | 레시피 ID |
| `region` | string | - | 지역 |
| `likes_count` | int | O | 좋아요 수 |
| `comments_count` | int | O | 댓글 수 |
| `created_at` | Timestamp | O | 생성 시각 (서버) |
| `updated_at` | Timestamp | O | 수정 시각 (서버) |
| `captured_at` | Timestamp | - | 촬영 시각 |

### posts/{postId}/likes/{userId}

| 필드 | 타입 | 설명 |
|------|------|------|
| `created_at` | Timestamp | 좋아요 시각 |

### posts/{postId}/comments/{commentId}

| 필드 | 타입 | 설명 |
|------|------|------|
| `comment_id` | string | 댓글 ID |
| `post_id` | string | 포스트 ID |
| `user_id` | string | 작성자 UID |
| `content` | string | 댓글 내용 |
| `created_at` | Timestamp | 생성 시각 |
| `updated_at` | Timestamp | 수정 시각 |

### users/{userId}/guestbook/{noteId}

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 노트 ID |
| `authorId` | string | 작성자 UID |
| `authorName` | string | 작성자 이름 |
| `authorAvatarUrl` | string | 작성자 아바타 URL |
| `text` | string | 노트 내용 |
| `color` | int | 배경색 (Color.value) |
| `pinned` | bool | 핀 여부 |
| `createdAt` | Timestamp | 생성 시각 |

---

## 직렬화/역직렬화 패턴

### Firestore → Dart 모델

모든 모델은 `factory ClassName.fromJson(Map<String, dynamic>)` 또는 `factory ClassName.fromMap(Map<String, dynamic>)` 패턴을 사용합니다:

```dart
// 일반 패턴
factory UserData.fromJson(Map<String, dynamic> json) {
  return UserData(
    userId: json['user_id'] ?? '',
    userName: json['user_name'] ?? '',
    // null 방어: ?? 연산자로 기본값 설정
  );
}
```

### Dart 모델 → Firestore

`toJson()` 메서드로 Map으로 변환합니다:

```dart
Map<String, dynamic> toJson() {
  return {
    'user_id': userId,
    'user_name': userName,
    // ...
  };
}
```

### 특수 패턴: FeedData

`FeedData`는 비동기로 여러 데이터를 조합해야 하므로, `static Future<FeedData> create()` 팩토리를 사용합니다. 일반 생성자는 `FeedData._internal()`로 private입니다.

### Timestamp 처리

Firestore `Timestamp`는 `PostData`에서 직접 사용되며, 포맷 변환은 유틸리티 함수로 처리합니다:

```dart
String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  return DateFormat('yyyy. MM. dd HH:mm').format(dateTime);
}
```

### Color 직렬화

`StickyNoteModel`에서 `Color`는 `int` (Color.value)로 저장/복원합니다:

```dart
// 저장: note.color.value → int
// 복원: Color(m['color'] as int)
```

---

## 관련 문서

- [기능 및 사용자 플로우](./FEATURES.md)
- [아키텍처](./ARCHITECTURE.md)
- [백엔드 통합](./BACKEND.md)
- [개발 환경 설정](./SETUP.md)
