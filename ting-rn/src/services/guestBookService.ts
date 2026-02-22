import firestore from '@react-native-firebase/firestore';
import { StickyNote } from '../types/guestbook';

function col(targetUserId: string) {
  return firestore()
    .collection('users')
    .doc(targetUserId)
    .collection('guestbook');
}

function fromDoc(d: any): StickyNote | null {
  const m = d?.data?.();
  if (!m) return null;
  return {
    id: (m.id as string) ?? d.id,
    authorId: (m.authorId as string) ?? '',
    authorName: (m.authorName as string) ?? '',
    authorAvatarUrl: (m.authorAvatarUrl as string) ?? '',
    createdAt: m.createdAt?.toDate?.() ?? new Date(),
    text: (m.text as string) ?? '',
    color: (m.color as number) ?? 0,
    pinned: (m.pinned as boolean) ?? false,
  };
}

export const guestBookService = {
  /** Returns a query for real-time listener */
  watchQuery(targetUserId: string) {
    return col(targetUserId)
      .orderBy('pinned', 'desc')
      .orderBy('createdAt', 'desc');
  },

  async addNote(targetUserId: string, note: StickyNote): Promise<void> {
    await col(targetUserId).doc(note.id).set(
      {
        id: note.id,
        authorId: note.authorId,
        authorName: note.authorName,
        authorAvatarUrl: note.authorAvatarUrl,
        text: note.text,
        color: note.color,
        pinned: note.pinned,
        createdAt: firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },

  async updateNote(targetUserId: string, note: StickyNote): Promise<void> {
    await col(targetUserId).doc(note.id).update({
      text: note.text,
      color: note.color,
      pinned: note.pinned,
    });
  },

  async deleteNote(targetUserId: string, noteId: string): Promise<void> {
    await col(targetUserId).doc(noteId).delete();
  },

  parseDoc: fromDoc,
};
