import { useState, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { postService } from '../services/postService';
import { useFirestoreDoc } from './useFirestoreStream';

/**
 * Optimistic like toggle.
 * Immediately flips UI state, then writes to Firestore.
 * Rolls back on failure.
 */
export function useLike(postId: string, postOwnerId: string) {
  const queryClient = useQueryClient();

  // Real-time source of truth
  const likeRef = postService.isLikedRef(postId);
  const { exists: isLiked, loading } = useFirestoreDoc(likeRef);

  // Optimistic override
  const [optimistic, setOptimistic] = useState<boolean | null>(null);
  const displayLiked = optimistic ?? isLiked;

  const toggle = useCallback(async () => {
    const current = optimistic ?? isLiked;
    setOptimistic(!current);

    try {
      await postService.toggleLike({
        postId,
        userId: postOwnerId,
        isCurrentlyLiked: current,
      });
      // Invalidate feed queries to refresh counts
      queryClient.invalidateQueries({ queryKey: ['feed'] });
    } catch {
      // Rollback
      setOptimistic(current);
    } finally {
      // Clear optimistic after Firestore snapshot catches up
      setTimeout(() => setOptimistic(null), 500);
    }
  }, [postId, postOwnerId, isLiked, optimistic, queryClient]);

  return { isLiked: displayLiked, loading, toggle };
}
