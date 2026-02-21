import { useState, useCallback } from 'react';
import { followService } from '../services/followService';
import { useFirestoreDoc } from './useFirestoreStream';

export function useFollow(targetUid: string) {
  const ref = followService.isFollowingRef(targetUid);
  const { exists: isFollowing, loading } = useFirestoreDoc(ref);

  const [optimistic, setOptimistic] = useState<boolean | null>(null);
  const displayFollowing = optimistic ?? isFollowing;

  const toggle = useCallback(async () => {
    const current = optimistic ?? isFollowing;
    setOptimistic(!current);

    try {
      if (current) {
        await followService.unfollow(targetUid);
      } else {
        await followService.follow(targetUid);
      }
    } catch {
      setOptimistic(current);
    } finally {
      setTimeout(() => setOptimistic(null), 500);
    }
  }, [targetUid, isFollowing, optimistic]);

  return { isFollowing: displayFollowing, loading, toggle };
}
