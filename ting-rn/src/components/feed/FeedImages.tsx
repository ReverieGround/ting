import { useState, useRef, useCallback } from 'react';
import {
  View,
  StyleSheet,
  Dimensions,
  FlatList,
  ViewToken,
} from 'react-native';
import { Image } from 'expo-image';
import { Tag } from '../common/Tag';

const SCREEN_WIDTH = Dimensions.get('window').width;

interface Props {
  imageUrls: string[];
  category?: string;
  value?: string;
  showTags?: boolean;
  height?: number;
  maxHeight?: number;
  aspectRatio?: number;
}

export function FeedImages({
  imageUrls,
  category,
  value,
  showTags = true,
  height,
  maxHeight = 350,
  aspectRatio = 4 / 3,
}: Props) {
  const [currentPage, setCurrentPage] = useState(0);
  const imgHeight = height ?? Math.min(SCREEN_WIDTH / aspectRatio, maxHeight);

  const onViewableItemsChanged = useRef(
    ({ viewableItems }: { viewableItems: ViewToken[] }) => {
      if (viewableItems.length > 0 && viewableItems[0].index != null) {
        setCurrentPage(viewableItems[0].index);
      }
    },
  ).current;

  const viewabilityConfig = useRef({ viewAreaCoveragePercentThreshold: 50 }).current;

  const renderImage = useCallback(
    ({ item }: { item: string }) => (
      <Image
        source={{ uri: item }}
        style={{ width: SCREEN_WIDTH, height: imgHeight, borderRadius: 5 }}
        contentFit="cover"
        transition={200}
        recyclingKey={item}
      />
    ),
    [imgHeight],
  );

  if (imageUrls.length === 0) return null;

  return (
    <View style={{ height: imgHeight }}>
      {imageUrls.length === 1 ? (
        <Image
          source={{ uri: imageUrls[0] }}
          style={{ width: SCREEN_WIDTH, height: imgHeight, borderRadius: 5 }}
          contentFit="cover"
          transition={200}
        />
      ) : (
        <FlatList
          data={imageUrls}
          renderItem={renderImage}
          keyExtractor={(url) => url}
          horizontal
          pagingEnabled
          showsHorizontalScrollIndicator={false}
          onViewableItemsChanged={onViewableItemsChanged}
          viewabilityConfig={viewabilityConfig}
          getItemLayout={(_, index) => ({
            length: SCREEN_WIDTH,
            offset: SCREEN_WIDTH * index,
            index,
          })}
        />
      )}

      {/* Tags overlay (top-left) */}
      {showTags && (category || value) && (
        <View style={styles.tagsOverlay}>
          {category ? <Tag label={category} /> : null}
          {value ? <Tag label={value} /> : null}
        </View>
      )}

      {/* Page indicator dots */}
      {imageUrls.length > 1 && (
        <View style={styles.dots}>
          {imageUrls.map((_, i) => (
            <View
              key={i}
              style={[styles.dot, i === currentPage && styles.dotActive]}
            />
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  tagsOverlay: {
    position: 'absolute',
    top: 10,
    left: 6,
    flexDirection: 'row',
    gap: 6,
  },
  dots: {
    position: 'absolute',
    bottom: 8,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 4,
  },
  dot: {
    width: 6,
    height: 5,
    borderRadius: 3,
    backgroundColor: 'rgba(255,255,255,0.3)',
  },
  dotActive: {
    backgroundColor: '#fff',
  },
});
