import { PostData } from './post';
import { UserData } from './user';

export interface FeedData {
  user: UserData;
  post: PostData;
  isPinned: boolean;
  isLikedByUser: boolean;
  numComments: number;
  numLikes: number;
}
