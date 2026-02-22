import { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  Pressable,
  FlatList,
  Dimensions,
  ActivityIndicator,
  StyleSheet,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Image } from 'expo-image';
import { colors, spacing } from '../../../../src/theme/colors';
import { userService } from '../../../../src/services/userService';
import { UserData } from '../../../../src/types/user';
import { ProfileAvatar } from '../../../../src/components/common/ProfileAvatar';

const TABS = ['팔로워', '팔로잉', '차단'] as const;
const TAB_KEYS = ['followers', 'following', 'blocks'] as const;
const COLUMNS = 3;
const GAP = 6;
const SCREEN_WIDTH = Dimensions.get('window').width;
const ITEM_WIDTH = (SCREEN_WIDTH - 24 - GAP * (COLUMNS - 1)) / COLUMNS;

export default function UserListPage() {
  const { userId } = useLocalSearchParams<{ userId: string }>();
  const params = useLocalSearchParams<{ tab?: string }>();
  const insets = useSafeAreaInsets();
  const router = useRouter();

  const initialTab = params.tab ? parseInt(params.tab, 10) : 0;
  const [tabIndex, setTabIndex] = useState(initialTab);
  const [users, setUsers] = useState<UserData[]>([]);
  const [loading, setLoading] = useState(true);
  const [cache, setCache] = useState<Record<string, UserData[]>>({});

  const fetchTab = useCallback(
    async (idx: number) => {
      const key = TAB_KEYS[idx];
      if (cache[key]) {
        setUsers(cache[key]);
        setLoading(false);
        return;
      }
      setLoading(true);
      try {
        const result = await userService.fetchUserList(userId ?? '', key);
        setUsers(result);
        setCache((prev) => ({ ...prev, [key]: result }));
      } catch {
        setUsers([]);
      } finally {
        setLoading(false);
      }
    },
    [userId, cache],
  );

  useEffect(() => {
    if (userId) fetchTab(tabIndex);
  }, [tabIndex, userId]); // eslint-disable-line react-hooks/exhaustive-deps

  const renderUser = useCallback(
    ({ item }: { item: UserData }) => (
      <Pressable
        style={styles.userCard}
        onPress={() => router.push(`/(tabs)/profile/${item.userId}`)}
      >
        <ProfileAvatar profileUrl={item.profileImage} size={64} />
        <Text style={styles.cardName} numberOfLines={1}>
          {item.userName}
        </Text>
        {item.title ? (
          <Text style={styles.cardTitle} numberOfLines={1}>
            {item.title}
          </Text>
        ) : null}
      </Pressable>
    ),
    [router],
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Tab bar */}
      <View style={styles.tabBar}>
        {TABS.map((label, i) => (
          <Pressable
            key={label}
            onPress={() => setTabIndex(i)}
            style={[styles.tab, tabIndex === i && styles.tabActive]}
          >
            <Text style={[styles.tabText, tabIndex === i && styles.tabTextActive]}>
              {label}
            </Text>
          </Pressable>
        ))}
      </View>

      {loading ? (
        <View style={styles.center}>
          <ActivityIndicator size="small" color={colors.primary} />
        </View>
      ) : users.length === 0 ? (
        <View style={styles.center}>
          <Text style={styles.emptyText}>목록이 비어있어요</Text>
        </View>
      ) : (
        <FlatList
          data={users}
          renderItem={renderUser}
          keyExtractor={(item) => item.userId}
          numColumns={COLUMNS}
          columnWrapperStyle={styles.row}
          contentContainerStyle={{
            padding: 12,
            paddingBottom: insets.bottom + 100,
          }}
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
  tabBar: {
    flexDirection: 'row',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.divider,
  },
  tab: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
  },
  tabActive: {
    borderBottomWidth: 2,
    borderBottomColor: colors.primary,
  },
  tabText: {
    fontSize: 14,
    fontWeight: '500',
    color: colors.hint,
  },
  tabTextActive: {
    color: colors.primary,
    fontWeight: '700',
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    color: colors.hint,
    fontSize: 14,
  },
  row: {
    gap: GAP,
    marginBottom: GAP,
  },
  userCard: {
    width: ITEM_WIDTH,
    alignItems: 'center',
    gap: 6,
  },
  cardName: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.primary,
    textAlign: 'center',
  },
  cardTitle: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.54)',
    textAlign: 'center',
  },
});
