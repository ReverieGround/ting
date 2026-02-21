import { View, Text, Pressable, StyleSheet } from 'react-native';
import { ProfileAvatar } from '../common/ProfileAvatar';
import { StickyNote } from '../../types/guestbook';
import { timeAgo } from '../../utils/formatTimestamp';

/** Pastel colors matching Flutter NoteColorPalette */
const NOTE_COLORS: Record<number, string> = {
  // Map ARGB int → hex string. Fall back to yellow.
};

function noteColor(argb: number): string {
  // Flutter stores as 0xAARRGGBB int
  const hex = `#${(argb & 0xffffff).toString(16).padStart(6, '0')}`;
  return hex;
}

interface Props {
  note: StickyNote;
  onPress?: () => void;
  onLongPress?: () => void;
  messy?: boolean;
}

export function StickyNoteCard({
  note,
  onPress,
  onLongPress,
  messy = true,
}: Props) {
  // Random rotation for messy mode (seeded by id for consistency)
  const seed = note.id.charCodeAt(0) + note.id.charCodeAt(note.id.length - 1);
  const rotation = messy ? ((seed % 11) - 5) * 0.8 : 0;

  return (
    <Pressable
      onPress={onPress}
      onLongPress={onLongPress}
      style={[
        styles.card,
        { backgroundColor: noteColor(note.color) },
        { transform: [{ rotate: `${rotation}deg` }] },
      ]}
    >
      {note.pinned && <Text style={styles.pin}>📌</Text>}
      <Text style={styles.text} numberOfLines={6}>
        {note.text}
      </Text>
      <View style={styles.footer}>
        <ProfileAvatar profileUrl={note.authorAvatarUrl} size={18} />
        <Text style={styles.author} numberOfLines={1}>
          {note.authorName}
        </Text>
        <Text style={styles.time}>{timeAgo(note.createdAt)}</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 4,
    padding: 12,
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 1, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 3,
    elevation: 3,
  },
  pin: {
    position: 'absolute',
    top: 4,
    right: 6,
    fontSize: 12,
  },
  text: {
    fontSize: 15,
    color: '#333',
    lineHeight: 22,
    // TODO: use NanumPenScript font when loaded
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 10,
  },
  author: {
    fontSize: 11,
    color: '#555',
    flex: 1,
  },
  time: {
    fontSize: 10,
    color: '#999',
  },
});
