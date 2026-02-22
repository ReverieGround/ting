import firestore from '@react-native-firebase/firestore';
import auth from '@react-native-firebase/auth';
import { PostData, Visibility, postFromMap } from '../types/post';
import { chunk } from '../utils/chunk';

async function isFollowing(viewerUid: string, ownerUid: string): Promise<boolean> {
  const doc = await firestore()
    .collection('users')
    .doc(ownerUid)
    .collection('followers')
    .doc(viewerUid)
    .get();
  return doc.exists();
}

export const postService = {
  getCurrentUserId(): string | null {
    return auth().currentUser?.uid ?? null;
  },

  async fetchUserPosts(params: {
    userId: string;
    limit?: number;
    excludeArchived?: boolean;
  }): Promise<PostData[]> {
    const limit = params.limit ?? 50;
    const excludeArchived = params.excludeArchived ?? true;
    const viewerUid = auth().currentUser?.uid;
    if (!viewerUid) return [];

    const isOwner = viewerUid === params.userId;
    const following = isOwner ? true : await isFollowing(viewerUid, params.userId);

    const canSee: Visibility[] = isOwner
      ? ['PUBLIC', 'FOLLOWER', 'PRIVATE']
      : following
        ? ['PUBLIC', 'FOLLOWER']
        : ['PUBLIC'];

    let q = firestore()
      .collection('posts')
      .where('user_id', '==', params.userId)
      .where('visibility', 'in', canSee)
      .orderBy('created_at', 'desc')
      .limit(limit);

    if (excludeArchived) {
      q = q.where('archived', '==', false);
    }

    const snap = await q.get();
    return snap.docs.map((d) => {
      const data = { ...d.data(), post_id: d.id } as Record<string, unknown>;
      return postFromMap(data);
    });
  },

  async fetchPinnedPosts(params: {
    ownerUserId?: string;
    limit?: number;
  }): Promise<PostData[]> {
    const uid = params.ownerUserId ?? auth().currentUser?.uid;
    if (!uid) return [];
    const limit = params.limit ?? 20;

    const pinnedSnap = await firestore()
      .collection('users')
      .doc(uid)
      .collection('pinned_posts')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();

    const ids = pinnedSnap.docs.map((d) => d.id);
    if (ids.length === 0) return [];

    const order = new Map(ids.map((id, i) => [id, i]));
    const chunks = chunk(ids, 10);

    const snaps = await Promise.all(
      chunks.map((g) =>
        firestore()
          .collection('posts')
          .where(firestore.FieldPath.documentId(), 'in', g)
          .get(),
      ),
    );

    const posts: PostData[] = [];
    for (const s of snaps) {
      for (const d of s.docs) {
        const data = {
          ...d.data(),
          post_id: d.id,
          comments: d.data().comments ?? [],
          image_urls: d.data().image_urls ?? [],
          likes_count: d.data().likes_count ?? 0,
          comments_count: d.data().comments_count ?? 0,
        } as Record<string, unknown>;
        posts.push(postFromMap(data));
      }
    }

    posts.sort(
      (a, b) => (order.get(a.postId) ?? Infinity) - (order.get(b.postId) ?? Infinity),
    );
    return posts;
  },

  async pinPost(postId: string): Promise<void> {
    const uid = auth().currentUser?.uid;
    if (!uid) return;
    await firestore()
      .collection('users')
      .doc(uid)
      .collection('pinned_posts')
      .doc(postId)
      .set({ created_at: firestore.FieldValue.serverTimestamp() }, { merge: true });
  },

  async unpinPost(postId: string): Promise<void> {
    const uid = auth().currentUser?.uid;
    if (!uid) return;
    await firestore()
      .collection('users')
      .doc(uid)
      .collection('pinned_posts')
      .doc(postId)
      .delete();
  },

  async togglePin(postId: string, isCurrentlyPinned: boolean): Promise<void> {
    if (isCurrentlyPinned) {
      await this.unpinPost(postId);
    } else {
      await this.pinPost(postId);
    }
  },

  async toggleLike(params: {
    postId: string;
    userId: string;
    isCurrentlyLiked: boolean;
  }): Promise<void> {
    const uid = auth().currentUser?.uid;
    if (!uid || uid === params.userId) return;

    const likeRef = firestore()
      .collection('posts')
      .doc(params.postId)
      .collection('likes')
      .doc(uid);
    const postRef = firestore().collection('posts').doc(params.postId);

    await firestore().runTransaction(async (tx) => {
      if (params.isCurrentlyLiked) {
        tx.delete(likeRef);
        tx.update(postRef, {
          likes_count: firestore.FieldValue.increment(-1),
        });
      } else {
        tx.set(likeRef, { created_at: firestore.FieldValue.serverTimestamp() });
        tx.update(postRef, {
          likes_count: firestore.FieldValue.increment(1),
        });
      }
    });
  },

  async addComment(params: {
    postId: string;
    content: string;
  }): Promise<string | null> {
    const uid = auth().currentUser?.uid;
    if (!uid) return null;

    const postRef = firestore().collection('posts').doc(params.postId);
    const commentRef = postRef.collection('comments').doc();

    await firestore().runTransaction(async (tx) => {
      tx.set(commentRef, {
        comment_id: commentRef.id,
        post_id: params.postId,
        user_id: uid,
        content: params.content.trim(),
        created_at: firestore.FieldValue.serverTimestamp(),
        updated_at: firestore.FieldValue.serverTimestamp(),
      });
      tx.update(postRef, {
        comments_count: firestore.FieldValue.increment(1),
        updated_at: firestore.FieldValue.serverTimestamp(),
      });
    });

    return commentRef.id;
  },

  async editComment(params: {
    postId: string;
    commentId: string;
    content: string;
  }): Promise<void> {
    await firestore()
      .collection('posts')
      .doc(params.postId)
      .collection('comments')
      .doc(params.commentId)
      .update({
        content: params.content.trim(),
        updated_at: firestore.FieldValue.serverTimestamp(),
      });
  },

  async deleteComment(params: {
    postId: string;
    commentId: string;
  }): Promise<void> {
    const postRef = firestore().collection('posts').doc(params.postId);
    const commentRef = postRef.collection('comments').doc(params.commentId);
    await firestore().runTransaction(async (tx) => {
      tx.delete(commentRef);
      tx.update(postRef, { comments_count: firestore.FieldValue.increment(-1) });
    });
  },

  commentsStream(postId: string, limit?: number) {
    let q = firestore()
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .orderBy('created_at', 'desc');
    if (limit) q = q.limit(limit);
    return q;
  },

  isLikedRef(postId: string) {
    const uid = auth().currentUser?.uid;
    if (!uid) return null;
    return firestore()
      .collection('posts')
      .doc(postId)
      .collection('likes')
      .doc(uid);
  },

  isPinnedRef(postId: string) {
    const uid = auth().currentUser?.uid;
    if (!uid) return null;
    return firestore()
      .collection('users')
      .doc(uid)
      .collection('pinned_posts')
      .doc(postId);
  },

  async createPost(params: {
    title: string;
    content: string;
    imageUrls: string[];
    visibility: Visibility;
    recipeId?: string;
    category: string;
    value: string;
    region?: string;
    capturedAt?: Date;
  }): Promise<string | null> {
    const uid = auth().currentUser?.uid;
    if (!uid) return null;

    const docRef = firestore().collection('posts').doc();
    await docRef.set({
      post_id: docRef.id,
      user_id: uid,
      title: params.title,
      content: params.content.trim(),
      image_urls: params.imageUrls,
      visibility: params.visibility,
      recipe_id: params.recipeId ?? null,
      category: params.category,
      value: params.value,
      region: params.region ?? '',
      likes_count: 0,
      comments_count: 0,
      archived: false,
      created_at: firestore.FieldValue.serverTimestamp(),
      updated_at: firestore.FieldValue.serverTimestamp(),
      captured_at: params.capturedAt
        ? firestore.Timestamp.fromDate(params.capturedAt)
        : firestore.FieldValue.serverTimestamp(),
    });

    return docRef.id;
  },

  async updateFields(params: {
    postId: string;
    visibility?: Visibility;
    category?: string;
    value?: string;
  }): Promise<void> {
    const data: Record<string, unknown> = {};
    if (params.visibility) data.visibility = params.visibility;
    if (params.category) data.category = params.category;
    if (params.value) data.value = params.value;
    if (Object.keys(data).length === 0) return;
    await firestore().collection('posts').doc(params.postId).update(data);
  },

  async softDelete(postId: string): Promise<void> {
    await firestore().collection('posts').doc(postId).update({ archived: true });
  },
};
