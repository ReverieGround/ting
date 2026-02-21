import { useQuery } from '@tanstack/react-query';
import { profileService } from '../services/profileService';

export function useProfile(userId?: string) {
  return useQuery({
    queryKey: ['profile', userId],
    queryFn: () => profileService.loadProfile(userId),
    enabled: !!userId || userId === undefined, // undefined = current user
  });
}
