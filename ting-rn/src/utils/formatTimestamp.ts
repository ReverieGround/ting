import { FirebaseFirestoreTypes } from '@react-native-firebase/firestore';

/** Format Firestore Timestamp → 'yyyy. MM. dd HH:mm' */
export function formatTimestamp(ts: FirebaseFirestoreTypes.Timestamp): string {
  const d = ts.toDate();
  const pad = (n: number) => n.toString().padStart(2, '0');
  return `${d.getFullYear()}. ${pad(d.getMonth() + 1)}. ${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** Relative time in Korean (방금 전, N분 전, N시간 전, ...) */
export function timeAgo(date: Date): string {
  const diff = Date.now() - date.getTime();
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (seconds < 60) return '방금 전';
  if (minutes < 60) return `${minutes}분 전`;
  if (hours < 24) return `${hours}시간 전`;
  if (days < 7) return `${days}일 전`;
  if (days < 30) return `${Math.floor(days / 7)}주 전`;
  if (days < 365) return `${Math.floor(days / 30)}개월 전`;

  const pad = (n: number) => n.toString().padStart(2, '0');
  return `${date.getFullYear()}. ${pad(date.getMonth() + 1)}. ${pad(date.getDate())}`;
}
