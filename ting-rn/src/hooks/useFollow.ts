import { useState, useCallback, useRef } from 'react';
import { Alert } from 'react-native';
import auth from '@react-native-firebase/auth';
import { followService } from '../services/followService';
import { useFirestoreDoc } from './useFirestoreStream';

export function useFollow(targetUid: string) {
  const ref = followService.isFollowingRef(targetUid);
  const { exists: isFollowing, loading } = useFirestoreDoc(ref);
  const busy = useRef(false);

  const [optimistic, setOptimistic] = useState<boolean | null>(null);
  const displayFollowing = optimistic ?? isFollowing;

  const toggle = useCallback(async () => {
    // Guard: prevent double-tap (matches Flutter _busy flag)
    if (busy.current) return;
    if (!ref) return;
    // Guard: prevent following self (matches Flutter FollowButton._toggle)
    const me = auth().currentUser?.uid;
    if (!me || me === targetUid) {
      Alert.alert('로그인 상태를 확인해주세요.');
      return;
    }

    busy.current = true;
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
      Alert.alert('처리할 수 없어요. 차단/권한을 확인하세요.');
    } finally {
      busy.current = false;
      setTimeout(() => setOptimistic(null), 500);
    }
  }, [targetUid, isFollowing, optimistic]);

  return { isFollowing: displayFollowing, loading, toggle };
}
