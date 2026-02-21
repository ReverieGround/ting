import { useCallback } from 'react';
import {
  View,
  Text,
  Pressable,
  FlatList,
  Dimensions,
  ActivityIndicator,
  StyleSheet,
} from 'react-native';
import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { PostData } from '../../types/post';
import { colors } from '../../theme/colors';

const COLUMNS = 3;
const GAP = 2;
const SCREEN_WIDTH = Dimensions.get('window').width;
const ITEM_SIZE = (SCREEN_WIDTH - GAP * (COLUMNS - 1)) / COLUMNS;

interface Props {
  posts: PostData[];
  loading?: boolean;
}

export function YumTab({ posts, loading }: Props) {
  const router = useRouter();

  // Only show posts with images
  const postsWithImages = posts.filter(
    (p) => p.imageUrls && p.imageUrls.length > 0,
  );

  const renderItem = useCallback(
    ({ item }: { item: PostData }) => (
      <Pressable
        onPress={() => router.push(`/(tabs)/feed/${item.postId}`)}
        style={styles.item}
      >
        <Image
          source={{ uri: item.imageUrls![0] }}
          style={styles.image}
          contentFit="cover"
          recyclingKey={item.postId}
        />
      </Pressable>
    ),
    [router],
  );

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="small" color={colors.primary} />
      </View>
    );
  }

  if (postsWithImages.length === 0) {
    return (
      <View style={styles.center}>
        <Text style={styles.empty}>아직 포스트가 없어요</Text>
      </View>
    );
  }

  return (
    <FlatList
      data={postsWithImages}
      renderItem={renderItem}
      keyExtractor={(item) => item.postId}
      numColumns={COLUMNS}
      columnWrapperStyle={{ gap: GAP }}
      contentContainerStyle={{ gap: GAP }}
      scrollEnabled={false}
    />
  );
}

const styles = StyleSheet.create({
  item: {
    width: ITEM_SIZE,
    height: ITEM_SIZE,
  },
  image: {
    width: '100%',
    height: '100%',
  },
  center: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  empty: {
    color: colors.hint,
    fontSize: 14,
  },
});
