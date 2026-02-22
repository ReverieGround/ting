import firestore from '@react-native-firebase/firestore';
import auth from '@react-native-firebase/auth';
import { PostData, postFromMap } from '../types/post';
import { FeedData } from '../types/feed';
import { userFromJson } from '../types/user';
import { chunk } from '../utils/chunk';

/** Build a FeedData by fetching user + engagement in parallel */
async function buildFeedData(post: PostData): Promise<FeedData> {
  const uid = auth().currentUser?.uid;
  const postRef = firestore().collection('posts').doc(post.postId);

  const [userSnap, likesCount, commentsCount, likeDoc, pinDoc] =
    await Promise.all([
      firestore().collection('users').doc(post.userId).get(),
      postRef.collection('likes').count().get(),
      postRef.collection('comments').count().get(),
      uid ? postRef.collection('likes').doc(uid).get() : Promise.resolve(null),
      uid
        ? firestore()
            .collection('users')
            .doc(uid)
            .collection('pinned_posts')
            .doc(post.postId)
            .get()
        : Promise.resolve(null),
    ]);

  if (!userSnap.exists()) throw new Error(`User ${post.userId} not found`);

  return {
    user: userFromJson(userSnap.data() as Record<string, unknown>),
    post,
    isPinned: pinDoc != null ? pinDoc.exists() : false,
    isLikedByUser: likeDoc != null ? likeDoc.exists() : false,
    numLikes: (likesCount as any)?.data?.()?.count ?? 0,
    numComments: (commentsCount as any)?.data?.()?.count ?? 0,
  };
}

export const feedService = {
  async fetchRealtimeFeeds(params: {
    limit: number;
    region?: string;
  }): Promise<FeedData[]> {
    let q = firestore()
      .collection('posts')
      .where('archived', '==', false)
      .where('visibility', '==', 'PUBLIC')
      .orderBy('created_at', 'desc')
      .limit(params.limit);

    if (params.region) {
      q = q.where('region', '==', params.region);
    }

    const snap = await q.get();
    if (snap.empty) return [];

    return Promise.all(
      snap.docs.map((d) =>
        buildFeedData(postFromMap(d.data() as Record<string, unknown>)),
      ),
    );
  },

  async fetchHotFeeds(params: {
    limit: number;
    region?: string;
  }): Promise<FeedData[]> {
    let q = firestore()
      .collection('posts')
      .where('archived', '==', false)
      .where('visibility', '==', 'PUBLIC')
      .where('likes_count', '>', 0)
      .orderBy('likes_count', 'desc')
      .limit(params.limit);

    if (params.region) {
      q = q.where('region', '==', params.region);
    }

    const snap = await q.get();
    if (snap.empty) return [];

    return Promise.all(
      snap.docs.map((d) =>
        buildFeedData(postFromMap(d.data() as Record<string, unknown>)),
      ),
    );
  },

  async fetchWackFeeds(params: {
    limit: number;
    region?: string;
  }): Promise<FeedData[]> {
    let q = firestore()
      .collection('posts')
      .where('archived', '==', false)
      .where('visibility', '==', 'PUBLIC')
      .where('value', '==', 'Wack')
      .orderBy('likes_count', 'desc')
      .limit(params.limit);

    if (params.region) {
      q = q.where('region', '==', params.region);
    }

    const snap = await q.get();
    if (snap.empty) return [];

    return Promise.all(
      snap.docs.map((d) =>
        buildFeedData(postFromMap(d.data() as Record<string, unknown>)),
      ),
    );
  },

  async fetchPersonalFeed(params: { limit?: number } = {}): Promise<FeedData[]> {
    const limit = params.limit ?? 50;
    const me = auth().currentUser?.uid;
    if (!me) throw new Error('User not logged in');

    const followingSnap = await firestore()
      .collection('users')
      .doc(me)
      .collection('following')
      .orderBy('created_at', 'desc')
      .get();
    let following = followingSnap.docs.map((d) => d.id);
    if (following.length === 0) return [];

    // Exclude blocked users
    const blocksSnap = await firestore()
      .collection('users')
      .doc(me)
      .collection('blocks')
      .get();
    const blocked = new Set(blocksSnap.docs.map((d) => d.id));
    following = following.filter((u) => !blocked.has(u));
    if (following.length === 0) return [];

    // whereIn has a 10-item limit
    const chunks = chunk(following, 10);
    const allDocs: any[] = [];

    for (const group of chunks) {
      const snap = await firestore()
        .collection('posts')
        .where('archived', '==', false)
        .where('visibility', '==', 'PUBLIC')
        .where('user_id', 'in', group)
        .orderBy('created_at', 'desc')
        .limit(limit)
        .get();
      allDocs.push(...snap.docs);
    }

    if (allDocs.length === 0) return [];

    // Sort combined and trim
    allDocs.sort((a, b) => {
      const aTime = (a.data().created_at?.toDate?.() ?? new Date(0)).getTime();
      const bTime = (b.data().created_at?.toDate?.() ?? new Date(0)).getTime();
      return bTime - aTime;
    });
    const trimmed = allDocs.slice(0, limit);

    return Promise.all(
      trimmed.map((doc) => {
        const data = { ...doc.data(), post_id: doc.id } as Record<string, unknown>;
        return buildFeedData(postFromMap(data));
      }),
    );
  },
};
