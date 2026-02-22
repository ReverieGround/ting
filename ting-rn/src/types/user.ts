export interface UserData {
  userId: string;
  userName: string;
  location: string;
  title: string;
  statusMessage?: string;
  profileImage?: string;
}

export function userFromJson(json: Record<string, unknown>): UserData {
  return {
    userId: (json.user_id as string) ?? '',
    userName: (json.user_name as string) ?? '',
    location: (json.location as string) ?? 'Seoul',
    title: (json.user_title as string) ?? '',
    statusMessage: (json.status_message as string) ?? '',
    profileImage: (json.profile_image as string) ?? '',
  };
}

export function userToJson(user: UserData): Record<string, unknown> {
  return {
    user_id: user.userId,
    user_name: user.userName,
    location: user.location,
    user_title: user.title,
    status_message: user.statusMessage,
    profile_image: user.profileImage,
  };
}

export interface ProfileInfo {
  userId: string;
  userName: string;
  location: string;
  statusMessage?: string;
  recipeCount: number;
  postCount: number;
  receivedLikeCount: number;
  followerCount: number;
  followingCount: number;
  profileImage?: string;
  userTitle: string;
}

export function profileInfoFromJson(json: Record<string, unknown>): ProfileInfo {
  return {
    userId: (json.user_id as string) ?? '',
    userName: (json.user_name as string) ?? '',
    location: (json.location as string) ?? '서울시',
    statusMessage: (json.status_message as string) ?? '',
    recipeCount: (json.recipe_count as number) ?? 0,
    postCount: (json.post_count as number) ?? 0,
    receivedLikeCount: (json.received_like_count as number) ?? 0,
    followerCount: (json.follower_count as number) ?? 0,
    followingCount: (json.following_count as number) ?? 0,
    profileImage: (json.profile_image as string) ?? '',
    userTitle: (json.user_title as string) ?? '',
  };
}

export const emptyProfileInfo: ProfileInfo = {
  userId: '',
  userName: '',
  location: '',
  statusMessage: '',
  recipeCount: 0,
  postCount: 0,
  receivedLikeCount: 0,
  followerCount: 0,
  followingCount: 0,
  profileImage: '',
  userTitle: '',
};
