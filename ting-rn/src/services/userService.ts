import firestore from '@react-native-firebase/firestore';
import auth from '@react-native-firebase/auth';
import storage from '@react-native-firebase/storage';
import { ProfileInfo, profileInfoFromJson, UserData } from '../types/user';

async function subcolCount(uid: string, sub: string): Promise<number> {
  const agg = await firestore()
    .collection('users')
    .doc(uid)
    .collection(sub)
    .count()
    .get();
  return (agg as any).data().count ?? 0;
}

async function isFollowingCheck(
  viewerUid: string,
  targetUid: string,
): Promise<boolean> {
  const d = await firestore()
    .collection('users')
    .doc(viewerUid)
    .collection('following')
    .doc(targetUid)
    .get();
  return d.exists();
}

async function postCount(
  ownerUid: string,
  viewerUid: string,
): Promise<number> {
  const isOwner = ownerUid === viewerUid;

  let visibilities: string[];
  if (isOwner) {
    visibilities = ['PUBLIC', 'FOLLOWER', 'PRIVATE'];
  } else {
    const following = await isFollowingCheck(viewerUid, ownerUid);
    visibilities = following ? ['PUBLIC', 'FOLLOWER'] : ['PUBLIC'];
  }

  try {
    const agg = await firestore()
      .collection('posts')
      .where('user_id', '==', ownerUid)
      .where('archived', '==', false)
      .where('visibility', 'in', visibilities)
      .count()
      .get();
    return (agg as any).data().count ?? 0;
  } catch {
    return 0;
  }
}

export const userService = {
  getCurrentUserId(): string | null {
    return auth().currentUser?.uid ?? null;
  },

  async fetchUserForViewer(
    targetUid: string,
    viewerUid?: string,
  ): Promise<ProfileInfo | null> {
    const viewer = viewerUid ?? auth().currentUser?.uid;
    if (!viewer) return null;

    let doc;
    try {
      doc = await firestore().collection('users').doc(targetUid).get();
    } catch {
      return null;
    }

    if (!doc.exists()) return null;
    const data: Record<string, unknown> = { ...doc.data() };

    delete data.email;
    delete data.phone;

    const [followerCnt, followingCnt, posts] = await Promise.all([
      subcolCount(targetUid, 'followers'),
      subcolCount(targetUid, 'following'),
      postCount(targetUid, viewer),
    ]);

    data.follower_count = followerCnt;
    data.following_count = followingCnt;
    data.post_count = posts;
    data.recipe_count = 0;

    if (viewer === targetUid) {
      const blockCnt = await subcolCount(targetUid, 'blocks');
      data.block_count = blockCnt;
    }

    return profileInfoFromJson(data);
  },

  async fetchUserRaw(uid: string): Promise<ProfileInfo | null> {
    const me = auth().currentUser?.uid;
    if (!me) return null;
    return this.fetchUserForViewer(uid, me);
  },

  async fetchUserRegion(targetUid?: string): Promise<string | null> {
    const uid = targetUid ?? auth().currentUser?.uid;
    if (!uid) return null;
    const info = await this.fetchUserForViewer(uid);
    return info?.location ?? null;
  },

  async uploadProfileImage(fileUri: string): Promise<string | null> {
    const uid = auth().currentUser?.uid;
    if (!uid) return null;

    try {
      const name = `profile_images/${uid}_${Date.now()}_${fileUri.split('/').pop()}`;
      const ref = storage().ref().child(name);
      await ref.putFile(fileUri);
      const url = await ref.getDownloadURL();
      await firestore().collection('users').doc(uid).update({ profile_image: url });
      return url;
    } catch {
      return null;
    }
  },

  async updateStatusMessage(message: string): Promise<boolean> {
    const uid = auth().currentUser?.uid;
    if (!uid) return false;
    try {
      await firestore()
        .collection('users')
        .doc(uid)
        .update({ status_message: message });
      return true;
    } catch {
      return false;
    }
  },

  async fetchUserList(
    targetUserId: string,
    type: 'followers' | 'following' | 'blocks',
  ): Promise<UserData[]> {
    try {
      const snap = await firestore()
        .collection('users')
        .doc(targetUserId)
        .collection(type)
        .get();
      if (snap.empty) return [];

      const results = await Promise.all(
        snap.docs.map(async (d): Promise<UserData | null> => {
          const userSnap = await firestore().collection('users').doc(d.id).get();
          if (!userSnap.exists()) return null;
          const ud = userSnap.data()!;
          return {
            userId: d.id,
            userName: (ud.user_name as string) ?? '',
            location: (ud.location as string) ?? '',
            title: (ud.user_title as string) ?? '',
            statusMessage: (ud.status_message as string) ?? undefined,
            profileImage: (ud.profile_image as string) ?? undefined,
          };
        }),
      );
      return results.filter((r): r is UserData => r !== null);
    } catch {
      return [];
    }
  },
};
