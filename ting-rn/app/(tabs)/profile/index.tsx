import { useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  ActivityIndicator,
  RefreshControl,
  StyleSheet,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import auth from '@react-native-firebase/auth';
import { colors, spacing } from '../../../src/theme/colors';
import { useProfile } from '../../../src/hooks/useProfile';
import { ProfileHeader } from '../../../src/components/profile/ProfileHeader';
import { YumTab } from '../../../src/components/profile/YumTab';
import { GuestBookTab } from '../../../src/components/profile/GuestBookTab';

type Tab = 'yum' | 'guestbook';

export default function MyProfilePage() {
  const insets = useSafeAreaInsets();
  const uid = auth().currentUser?.uid;
  const { data: profile, isLoading, refetch, isRefetching } = useProfile(uid);
  const [tab, setTab] = useState<Tab>('yum');

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
      <ProfileHeader profile={profile.profileInfo} isOwner />

      {/* Tab bar */}
      <View style={styles.tabBar}>
        <TabButton label="Yum" active={tab === 'yum'} onPress={() => setTab('yum')} />
        <TabButton
          label="방명록"
          active={tab === 'guestbook'}
          onPress={() => setTab('guestbook')}
        />
      </View>

      {/* Tab content */}
      {tab === 'yum' ? (
        <YumTab posts={profile.posts} />
      ) : (
        <GuestBookTab userId={profile.profileInfo.userId} />
      )}
    </ScrollView>
  );
}

function TabButton({
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
