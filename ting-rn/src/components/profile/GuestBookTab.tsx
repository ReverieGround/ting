import { useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  Dimensions,
  ActivityIndicator,
  StyleSheet,
} from 'react-native';
import { StickyNoteCard } from './StickyNoteCard';
import { StickyNote } from '../../types/guestbook';
import { useFirestoreQuery } from '../../hooks/useFirestoreStream';
import { guestBookService } from '../../services/guestBookService';
import { colors } from '../../theme/colors';

const SCREEN_WIDTH = Dimensions.get('window').width;
const COLUMNS = SCREEN_WIDTH > 520 ? 3 : 2;

interface Props {
  userId: string;
}

function transformNote(data: Record<string, unknown>, id: string): StickyNote {
  return {
    id: (data.id as string) ?? id,
    authorId: (data.authorId as string) ?? '',
    authorName: (data.authorName as string) ?? '',
    authorAvatarUrl: (data.authorAvatarUrl as string) ?? '',
    createdAt: (data.createdAt as any)?.toDate?.() ?? new Date(),
    text: (data.text as string) ?? '',
    color: (data.color as number) ?? 0xfffff2b2,
    pinned: (data.pinned as boolean) ?? false,
  };
}

export function GuestBookTab({ userId }: Props) {
  const query = guestBookService.watchQuery(userId);
  const { data: notes, loading } = useFirestoreQuery(query, transformNote);

  const renderItem = useCallback(
    ({ item }: { item: StickyNote }) => <StickyNoteCard note={item} />,
    [],
  );

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="small" color={colors.primary} />
      </View>
    );
  }

  if (notes.length === 0) {
    return (
      <View style={styles.center}>
        <Text style={styles.empty}>방명록이 비어있어요</Text>
      </View>
    );
  }

  return (
    <FlatList
      data={notes}
      renderItem={renderItem}
      keyExtractor={(item) => item.id}
      numColumns={COLUMNS}
      columnWrapperStyle={styles.row}
      contentContainerStyle={styles.grid}
      scrollEnabled={false}
    />
  );
}

const styles = StyleSheet.create({
  center: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  empty: {
    color: colors.hint,
    fontSize: 14,
  },
  grid: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  row: {
    gap: 12,
    marginBottom: 12,
  },
});
