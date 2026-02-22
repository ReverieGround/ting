import { useState, useCallback, useRef } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { postService } from '../services/postService';
import { useFirestoreDoc } from './useFirestoreStream';

/**
 * Optimistic like toggle.
 * Immediately flips UI state, then writes to Firestore.
 * Rolls back on failure. Guards against self-like and double-tap.
 */
export function useLike(postId: string, postOwnerId: string) {
  const queryClient = useQueryClient();
  const toggling = useRef(false);

  // Real-time source of truth
  const likeRef = postService.isLikedRef(postId);
  const { exists: isLiked, loading } = useFirestoreDoc(likeRef);

  // Optimistic override
  const [optimistic, setOptimistic] = useState<boolean | null>(null);
  const displayLiked = optimistic ?? isLiked;

  const toggle = useCallback(async () => {
    // Guard: prevent liking own posts (matches Flutter LikeIcon._toggleLike)
    const me = postService.getCurrentUserId();
    if (me === postOwnerId) return;
    // Guard: prevent double-tap (matches Flutter _isToggling flag)
    if (toggling.current) return;
    if (!likeRef) return;

    toggling.current = true;
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
      toggling.current = false;
      // Clear optimistic after Firestore snapshot catches up
      setTimeout(() => setOptimistic(null), 500);
    }
  }, [postId, postOwnerId, isLiked, optimistic, queryClient]);

  return { isLiked: displayLiked, loading, toggle };
}
