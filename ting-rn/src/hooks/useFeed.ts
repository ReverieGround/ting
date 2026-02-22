import { useQuery } from '@tanstack/react-query';
import { feedService } from '../services/feedService';

export function useRealtimeFeed(limit = 20) {
  return useQuery({
    queryKey: ['feed', 'realtime', limit],
    queryFn: () => feedService.fetchRealtimeFeeds({ limit }),
  });
}

export function useHotFeed(limit = 20) {
  return useQuery({
    queryKey: ['feed', 'hot', limit],
    queryFn: () => feedService.fetchHotFeeds({ limit }),
  });
}

export function useWackFeed(limit = 20) {
  return useQuery({
    queryKey: ['feed', 'wack', limit],
    queryFn: () => feedService.fetchWackFeeds({ limit }),
  });
}

export function usePersonalFeed(limit = 50) {
  return useQuery({
    queryKey: ['feed', 'personal', limit],
    queryFn: () => feedService.fetchPersonalFeed({ limit }),
  });
}
