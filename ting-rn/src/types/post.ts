import { FirebaseFirestoreTypes } from '@react-native-firebase/firestore';

export type Visibility = 'PUBLIC' | 'FOLLOWER' | 'PRIVATE';

export interface PostData {
  userId: string;
  postId: string;
  title: string;
  content: string;
  comments?: unknown[];
  imageUrls?: string[];
  likesCount: number;
  commentsCount: number;
  category: string;
  value?: string;
  recipeId?: string;
  createdAt: FirebaseFirestoreTypes.Timestamp;
  updatedAt: FirebaseFirestoreTypes.Timestamp;
  visibility: Visibility;
  archived: boolean;
}

export function postFromMap(data: Record<string, unknown>): PostData {
  return {
    userId: data.user_id as string,
    postId: data.post_id as string,
    title: data.title as string,
    content: data.content as string,
    comments: (data.comments as unknown[]) ?? [],
    imageUrls: (data.image_urls as string[]) ?? [],
    likesCount: (data.likes_count as number) ?? 0,
    commentsCount: (data.comments_count as number) ?? 0,
    category: data.category as string,
    value: data.value as string | undefined,
    recipeId: data.recipe_id as string | undefined,
    createdAt: data.created_at as FirebaseFirestoreTypes.Timestamp,
    updatedAt: data.updated_at as FirebaseFirestoreTypes.Timestamp,
    visibility: (data.visibility as Visibility) ?? 'PUBLIC',
    archived: (data.archived as boolean) ?? false,
  };
}

/** Form input data for creating posts */
export interface PostInputData {
  imageUris: string[];
  selectedValue: string;
  selectedCategory: string;
  capturedDate: string;
  recommendRecipe: boolean;
  mealKitLink: string;
  restaurantLink: string;
  deliveryLink: string;
  content: string;
}
