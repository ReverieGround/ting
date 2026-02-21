import { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  ActivityIndicator,
  RefreshControl,
  StyleSheet,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import auth from '@react-native-firebase/auth';
import { colors } from '../../../src/theme/colors';
import { useProfile } from '../../../src/hooks/useProfile';
import { ProfileHeader } from '../../../src/components/profile/ProfileHeader';
import { FollowButton } from '../../../src/components/profile/FollowButton';
import { YumTab } from '../../../src/components/profile/YumTab';
import { GuestBookTab } from '../../../src/components/profile/GuestBookTab';

type Tab = 'yum' | 'guestbook';

export default function UserProfilePage() {
  const { userId } = useLocalSearchParams<{ userId: string }>();
  const insets = useSafeAreaInsets();
  const { data: profile, isLoading, refetch, isRefetching } = useProfile(userId);
  const [tab, setTab] = useState<Tab>('yum');
  const isOwner = auth().currentUser?.uid === userId;

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

      {/* Tab bar */}
      <View style={styles.tabBar}>
        <TabBtn label="Yum" active={tab === 'yum'} onPress={() => setTab('yum')} />
        <TabBtn
          label="방명록"
          active={tab === 'guestbook'}
          onPress={() => setTab('guestbook')}
        />
      </View>

      {tab === 'yum' ? (
        <YumTab posts={profile.posts} />
      ) : (
        <GuestBookTab userId={profile.profileInfo.userId} />
      )}
    </ScrollView>
  );
}

import { Dimensions } from 'react-native';
const SCREEN_WIDTH = Dimensions.get('window').width;

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
  tabBar: {
    flexDirection: 'row',
    marginTop: 16,
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
});
