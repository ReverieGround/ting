import firestore from '@react-native-firebase/firestore';
import auth from '@react-native-firebase/auth';
import { FollowEntry } from '../types/guestbook';

function me(): string | null {
  return auth().currentUser?.uid ?? null;
}

export const followService = {
  async follow(targetUid: string): Promise<boolean> {
    const uid = me();
    if (!uid || uid === targetUid) return false;

    // Check if blocked by me
    try {
      const blockedSnap = await firestore()
        .collection('users')
        .doc(uid)
        .collection('blocks')
        .doc(targetUid)
        .get();
      if (blockedSnap.exists()) return false;
    } catch {
      // continue — rules will catch at commit
    }

    const batch = firestore().batch();
    batch.set(
      firestore()
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid),
      { created_at: firestore.FieldValue.serverTimestamp() },
    );
    batch.set(
      firestore()
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid),
      { created_at: firestore.FieldValue.serverTimestamp() },
    );

    try {
      await batch.commit();
      return true;
    } catch (e: any) {
      if (e?.code === 'permission-denied') return false;
      throw e;
    }
  },

  async unfollow(targetUid: string): Promise<boolean> {
    const uid = me();
    if (!uid || uid === targetUid) return false;

    const batch = firestore().batch();
    batch.delete(
      firestore()
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid),
    );
    batch.delete(
      firestore()
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid),
    );
    await batch.commit();
    return true;
  },

  async block(targetUid: string): Promise<boolean> {
    const uid = me();
    if (!uid || uid === targetUid) return false;

    const batch = firestore().batch();
    // Add block
    batch.set(
      firestore().collection('users').doc(uid).collection('blocks').doc(targetUid),
      { created_at: firestore.FieldValue.serverTimestamp() },
    );
    // Remove both follow directions
    batch.delete(
      firestore().collection('users').doc(uid).collection('following').doc(targetUid),
    );
    batch.delete(
      firestore()
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid),
    );
    batch.delete(
      firestore()
        .collection('users')
        .doc(targetUid)
        .collection('following')
        .doc(uid),
    );
    batch.delete(
      firestore().collection('users').doc(uid).collection('followers').doc(targetUid),
    );
    await batch.commit();
    return true;
  },

  async unblock(targetUid: string): Promise<boolean> {
    const uid = me();
    if (!uid || uid === targetUid) return false;
    await firestore()
      .collection('users')
      .doc(uid)
      .collection('blocks')
      .doc(targetUid)
      .delete();
    return true;
  },

  async followerCount(userId: string): Promise<number> {
    const agg = await firestore()
      .collection('users')
      .doc(userId)
      .collection('followers')
      .count()
      .get();
    return (agg as any)?.data?.()?.count ?? 0;
  },

  async followingCount(userId: string): Promise<number> {
    const agg = await firestore()
      .collection('users')
      .doc(userId)
      .collection('following')
      .count()
      .get();
    return (agg as any)?.data?.()?.count ?? 0;
  },

  /** Returns a Firestore ref for real-time isFollowing check */
  isFollowingRef(targetUid: string) {
    const uid = me();
    if (!uid) return null;
    return firestore()
      .collection('users')
      .doc(uid)
      .collection('following')
      .doc(targetUid);
  },

  isBlockedRef(targetUid: string) {
    const uid = me();
    if (!uid) return null;
    return firestore()
      .collection('users')
      .doc(uid)
      .collection('blocks')
      .doc(targetUid);
  },

  async fetchFollowersPage(params: {
    userId: string;
    limit?: number;
  }): Promise<FollowEntry[]> {
    const limit = params.limit ?? 30;
    const snap = await firestore()
      .collection('users')
      .doc(params.userId)
      .collection('followers')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();
    return snap.docs.map((d) => ({
      uid: d.id,
      createdAt: d.data().created_at?.toDate?.() ?? undefined,
    }));
  },

  async fetchFollowingPage(params: {
    userId: string;
    limit?: number;
  }): Promise<FollowEntry[]> {
    const limit = params.limit ?? 30;
    const snap = await firestore()
      .collection('users')
      .doc(params.userId)
      .collection('following')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();
    return snap.docs.map((d) => ({
      uid: d.id,
      createdAt: d.data().created_at?.toDate?.() ?? undefined,
    }));
  },

  async fetchBlockedPage(params: {
    userId: string;
    limit?: number;
  }): Promise<FollowEntry[]> {
    const limit = params.limit ?? 30;
    const snap = await firestore()
      .collection('users')
      .doc(params.userId)
      .collection('blocks')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();
    return snap.docs.map((d) => ({
      uid: d.id,
      createdAt: d.data().created_at?.toDate?.() ?? undefined,
    }));
  },
};
