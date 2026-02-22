export interface StickyNote {
  id: string;
  authorId: string;
  authorName: string;
  authorAvatarUrl: string;
  createdAt: Date;
  text: string;
  /** Stored as ARGB int in Firestore */
  color: number;
  pinned: boolean;
}

export interface FollowEntry {
  uid: string;
  createdAt?: Date;
}
