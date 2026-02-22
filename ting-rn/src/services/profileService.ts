import auth from '@react-native-firebase/auth';
import { userService } from './userService';
import { postService } from './postService';
import { ProfileInfo } from '../types/user';
import { PostData } from '../types/post';

export interface ProfileData {
  profileInfo: ProfileInfo;
  posts: PostData[];
  pinned: PostData[];
}

export const profileService = {
  async loadProfile(targetUserId?: string): Promise<ProfileData | null> {
    const uid = targetUserId ?? auth().currentUser?.uid;
    if (!uid) return null;

    const profileInfo = await userService.fetchUserRaw(uid);
    if (!profileInfo) return null;

    const [posts, pinned] = await Promise.all([
      postService.fetchUserPosts({ userId: uid, limit: 50, excludeArchived: true }),
      postService.fetchPinnedPosts({ ownerUserId: uid, limit: 20 }),
    ]);

    return { profileInfo, posts, pinned };
  },
};
