import { useCallback, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  RefreshControl,
  ActivityIndicator,
  TextInput,
  Pressable,
} from 'react-native';
import { FlashList } from '@shopify/flash-list';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../../src/theme/colors';
import {
  useRealtimeFeed,
  useHotFeed,
  useWackFeed,
  usePersonalFeed,
} from '../../../src/hooks/useFeed';
import { FeedCard } from '../../../src/components/feed/FeedCard';
import { FeedData } from '../../../src/types/feed';

const FEED_LIMIT = 20;

type FeedType = 'realtime' | 'hot' | 'wack' | 'personal';

const FEED_TABS: { key: FeedType; label: string }[] = [
  { key: 'realtime', label: '전체' },
  { key: 'hot', label: 'Hot' },
  { key: 'wack', label: 'Wack' },
  { key: 'personal', label: 'Personal' },
];

export default function FeedPage() {
  const insets = useSafeAreaInsets();
  const [feedType, setFeedType] = useState<FeedType>('realtime');
  const [searchText, setSearchText] = useState('');

  const realtime = useRealtimeFeed(FEED_LIMIT);
  const hot = useHotFeed(FEED_LIMIT);
  const wack = useWackFeed(FEED_LIMIT);
  const personal = usePersonalFeed(FEED_LIMIT);

  const feedMap = { realtime, hot, wack, personal };
  const current = feedMap[feedType];
  const { data: feeds, isLoading, refetch, isRefetching } = current;

  const handleSearch = () => {
    const text = searchText.trim();
    if (!text) return;
    // TODO: search logic
  };

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

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Feed filter toggle — matches Flutter FeedFilterToggle */}
      <View style={styles.filterBar}>
        <View style={styles.filterTabs}>
          {FEED_TABS.map((tab) => {
            const isSelected = feedType === tab.key;
            return (
              <Pressable
                key={tab.key}
                onPress={() => setFeedType(tab.key)}
                style={[
                  styles.filterTab,
                  isSelected && styles.filterTabActive,
                ]}
              >
                <Text
                  style={[
                    styles.filterLabel,
                    isSelected && styles.filterLabelActive,
                  ]}
                >
                  {tab.label}
                </Text>
              </Pressable>
            );
          })}
        </View>

        {/* Search bar */}
        <View style={styles.searchWrap}>
          <TextInput
            style={styles.searchInput}
            value={searchText}
            onChangeText={setSearchText}
            placeholder="검색"
            placeholderTextColor="rgba(255,255,255,0.54)"
            cursorColor="#FFFFFF"
            returnKeyType="search"
            onSubmitEditing={handleSearch}
          />
          <Pressable onPress={handleSearch} style={styles.searchIcon}>
            <Ionicons name="search" size={20} color="#FFFFFF" />
          </Pressable>
        </View>
      </View>

      {isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      ) : !feeds || feeds.length === 0 ? (
        <View style={styles.center}>
          <Text style={styles.empty}>아직 포스트가 없어요</Text>
        </View>
      ) : (
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
      )}
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

  // Filter bar — matches Flutter FeedFilterToggle
  filterBar: {
    height: 52,
    flexDirection: 'row',
    alignItems: 'center',
    paddingLeft: 8,
    paddingRight: 12,
    backgroundColor: 'rgba(15,17,21,0.95)',
  },
  filterTabs: {
    flexDirection: 'row',
  },
  filterTab: {
    marginHorizontal: 10,
    paddingVertical: 6,
    borderBottomWidth: 2.5,
    borderBottomColor: 'transparent',
  },
  filterTabActive: {
    borderBottomColor: colors.primary,
  },
  filterLabel: {
    fontSize: 15,
    fontWeight: '400',
    color: 'rgba(255,255,255,0.7)',
    letterSpacing: 0.3,
  },
  filterLabelActive: {
    fontWeight: '600',
    color: colors.primary,
  },

  // Search bar
  searchWrap: {
    flex: 1,
    marginLeft: 'auto' as any,
    maxWidth: 150,
    height: 32,
    borderRadius: 30,
    backgroundColor: '#212121',
    flexDirection: 'row',
    alignItems: 'center',
    overflow: 'hidden',
  },
  searchInput: {
    flex: 1,
    color: '#FFFFFF',
    fontSize: 14,
    paddingVertical: 5,
    paddingHorizontal: 16,
  },
  searchIcon: {
    paddingRight: 8,
  },
});
