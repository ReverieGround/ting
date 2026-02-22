import { useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  ActivityIndicator,
  RefreshControl,
  Alert,
  StyleSheet,
  Dimensions,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import auth from '@react-native-firebase/auth';
import { colors } from '../../../src/theme/colors';
import { useProfile } from '../../../src/hooks/useProfile';
import { postService } from '../../../src/services/postService';
import { ProfileHeader } from '../../../src/components/profile/ProfileHeader';
import { FollowButton } from '../../../src/components/profile/FollowButton';
import { YumTab } from '../../../src/components/profile/YumTab';
import { GuestBookTab } from '../../../src/components/profile/GuestBookTab';
import { PostData } from '../../../src/types/post';

const SCREEN_WIDTH = Dimensions.get('window').width;

type Tab = 'yum' | 'pinned' | 'guestbook';

export default function UserProfilePage() {
  const { userId } = useLocalSearchParams<{ userId: string }>();
  const insets = useSafeAreaInsets();
  const { data: profile, isLoading, refetch, isRefetching } = useProfile(userId);
  const [tab, setTab] = useState<Tab>('yum');
  const isOwner = auth().currentUser?.uid === userId;

  const handlePin = useCallback(
    async (post: PostData) => {
      if (!isOwner) return; // only owner can pin
      try {
        await postService.pinPost(post.postId);
        refetch();
        Alert.alert('상단에 고정했습니다');
      } catch {
        Alert.alert('고정 실패', '잠시 후 다시 시도해 주세요');
      }
    },
    [isOwner, refetch],
  );

  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (!profile) {
    return (
      <View style={styles.center}>
        <Text style={styles.emptyText}>프로필을 불러올 수 없습니다</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={[styles.container, { paddingTop: insets.top }]}
      contentContainerStyle={{ paddingBottom: insets.bottom + 100 }}
      refreshControl={
        <RefreshControl
          refreshing={isRefetching}
          onRefresh={refetch}
          tintColor={colors.primary}
        />
      }
    >
      <ProfileHeader profile={profile.profileInfo} isOwner={isOwner} />

      {!isOwner && userId && (
        <FollowButton targetUid={userId} width={SCREEN_WIDTH - 32} />
      )}

      {/* Pinned feeds grid — shown above tabs like Flutter PinnedFeedsGrid */}
      {profile.pinned.length > 0 && (
        <YumTab posts={profile.pinned} />
      )}

      {/* Tab bar — matches Flutter TabBar style */}
      <View style={styles.tabBar}>
        <TabBtn label="Yum" active={tab === 'yum'} onPress={() => setTab('yum')} />
        <TabBtn label="Pin" active={tab === 'pinned'} onPress={() => setTab('pinned')} />
        <TabBtn
          label="Guestbook"
          active={tab === 'guestbook'}
          onPress={() => setTab('guestbook')}
        />
      </View>

      {tab === 'yum' ? (
        <YumTab posts={profile.posts} onPin={isOwner ? handlePin : undefined} />
      ) : tab === 'pinned' ? (
        profile.pinned.length > 0 ? (
          <YumTab posts={profile.pinned} onPin={isOwner ? handlePin : undefined} />
        ) : (
          <View style={styles.emptyTab}>
            <Text style={styles.emptyText}>핀 고정된 포스트가 없어요</Text>
          </View>
        )
      ) : (
        <GuestBookTab userId={profile.profileInfo.userId} />
      )}
    </ScrollView>
  );
}

function TabBtn({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={[styles.tab, active && styles.tabActive]}
    >
      <Text style={[styles.tabText, active && styles.tabTextActive]}>
        {label}
      </Text>
    </Pressable>
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
  emptyText: {
    color: colors.hint,
    fontSize: 16,
  },
  emptyTab: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  tabBar: {
    flexDirection: 'row',
    height: 36,
    paddingHorizontal: 8,
    marginTop: 16,
    alignItems: 'flex-end',
  },
  tab: {
    flex: 1,
    height: 30,
    justifyContent: 'center',
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabActive: {
    borderBottomColor: colors.primary,
  },
  tabText: {
    fontSize: 14,
    fontWeight: '500',
    color: 'rgba(234,236,239,0.6)',
  },
  tabTextActive: {
    color: colors.primary,
    fontWeight: '700',
  },
});
