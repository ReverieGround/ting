import { useCallback, useState } from 'react';
import { View, Text, StyleSheet, RefreshControl, ActivityIndicator } from 'react-native';
import { FlashList } from '@shopify/flash-list';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors } from '../../../src/theme/colors';
import { useRealtimeFeed } from '../../../src/hooks/useFeed';
import { FeedCard } from '../../../src/components/feed/FeedCard';
import { FeedData } from '../../../src/types/feed';

const FEED_LIMIT = 20;

export default function FeedPage() {
  const insets = useSafeAreaInsets();
  const { data: feeds, isLoading, refetch, isRefetching } = useRealtimeFeed(FEED_LIMIT);

  const renderItem = useCallback(
    ({ item }: { item: FeedData }) => (
      <FeedCard
        feed={item}
        showTags={false}
        showContent={false}
        showIcons={false}
        overlayTopWriter
        imageHeight={350}
      />
    ),
    [],
  );

  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (!feeds || feeds.length === 0) {
    return (
      <View style={styles.center}>
        <Text style={styles.empty}>아직 포스트가 없어요</Text>
      </View>
    );
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <FlashList
        data={feeds}
        renderItem={renderItem}
        keyExtractor={(item) => item.post.postId}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={refetch}
            tintColor={colors.primary}
          />
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + 90 }}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.bgLight,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bgLight,
  },
  empty: {
    color: colors.hint,
    fontSize: 16,
  },
  separator: {
    height: 8,
  },
});
