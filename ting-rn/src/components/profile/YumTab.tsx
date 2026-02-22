import { useCallback, useState } from 'react';
import {
  View,
  Text,
  Pressable,
  FlatList,
  Dimensions,
  ActivityIndicator,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TouchableWithoutFeedback,
} from 'react-native';
import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { PostData } from '../../types/post';
import { colors } from '../../theme/colors';

const COLUMNS = 3;
const GAP = 4;
const SCREEN_WIDTH = Dimensions.get('window').width;
const ITEM_SIZE = (SCREEN_WIDTH - 16 - GAP * (COLUMNS - 1)) / COLUMNS; // padding 8 each side

interface Props {
  posts: PostData[];
  loading?: boolean;
  onPin?: (post: PostData) => void;
}

export function YumTab({ posts, loading, onPin }: Props) {
  const router = useRouter();
  const [previewPost, setPreviewPost] = useState<PostData | null>(null);

  // Only show posts with images
  const postsWithImages = posts.filter(
    (p) => p.imageUrls && p.imageUrls.length > 0,
  );

  const handleLongPress = useCallback(
    (item: PostData) => {
      if (onPin) {
        setPreviewPost(item);
      }
    },
    [onPin],
  );

  const handlePin = useCallback(() => {
    if (previewPost && onPin) {
      onPin(previewPost);
    }
    setPreviewPost(null);
  }, [previewPost, onPin]);

  const renderItem = useCallback(
    ({ item }: { item: PostData }) => (
      <Pressable
        onPress={() => router.push(`/(tabs)/feed/${item.postId}`)}
        onLongPress={() => handleLongPress(item)}
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
    [router, handleLongPress],
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
    <>
      <FlatList
        data={postsWithImages}
        renderItem={renderItem}
        keyExtractor={(item) => item.postId}
        numColumns={COLUMNS}
        columnWrapperStyle={{ gap: GAP }}
        contentContainerStyle={{ gap: GAP, padding: 8 }}
        scrollEnabled={false}
      />

      {/* Long-press preview dialog — matches Flutter _openPreview */}
      <Modal
        visible={!!previewPost}
        transparent
        animationType="fade"
        onRequestClose={() => setPreviewPost(null)}
      >
        <TouchableWithoutFeedback onPress={() => setPreviewPost(null)}>
          <View style={styles.overlay}>
            <TouchableWithoutFeedback>
              <View style={styles.previewContainer}>
                {previewPost?.imageUrls?.[0] ? (
                  <Image
                    source={{ uri: previewPost.imageUrls[0] }}
                    style={styles.previewImage}
                    contentFit="cover"
                  />
                ) : null}
                <View style={styles.previewActions}>
                  <TouchableOpacity
                    style={styles.pinButton}
                    onPress={handlePin}
                  >
                    <Ionicons
                      name="pin-outline"
                      size={16}
                      color={colors.primary}
                    />
                    <Text style={styles.pinText}>상단 고정하기</Text>
                  </TouchableOpacity>
                </View>
              </View>
            </TouchableWithoutFeedback>
          </View>
        </TouchableWithoutFeedback>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  item: {
    width: ITEM_SIZE,
    height: ITEM_SIZE,
    borderRadius: 12,
    overflow: 'hidden',
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

  // Preview dialog — matches Flutter _openPreview
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.35)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  previewContainer: {
    maxWidth: 400,
    maxHeight: 450,
    padding: 8,
  },
  previewImage: {
    width: 300,
    height: 300,
    borderRadius: 10,
  },
  previewActions: {
    flexDirection: 'row',
    marginTop: 5,
  },
  pinButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: 'rgba(255,255,255,0.12)',
    paddingHorizontal: 8,
    paddingVertical: 8,
    borderRadius: 10,
  },
  pinText: {
    fontSize: 13,
    color: colors.primary,
  },
});
