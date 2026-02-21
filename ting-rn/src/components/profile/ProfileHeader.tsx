import { View, Text, Pressable, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { ProfileAvatar } from '../common/ProfileAvatar';
import { ProfileInfo } from '../../types/user';
import { colors, spacing } from '../../theme/colors';
import { formatNumber } from '../../utils/formatNumber';

interface Props {
  profile: ProfileInfo;
  isOwner: boolean;
}

export function ProfileHeader({ profile, isOwner }: Props) {
  const router = useRouter();

  const stats = [
    { label: 'Yum', value: profile.postCount },
    { label: '레시피', value: profile.recipeCount },
    {
      label: '팔로워',
      value: profile.followerCount,
      onPress: () =>
        router.push(`/(tabs)/users/${profile.userId}/list?tab=0`),
    },
    {
      label: '팔로잉',
      value: profile.followingCount,
      onPress: () =>
        router.push(`/(tabs)/users/${profile.userId}/list?tab=1`),
    },
  ];

  return (
    <View style={styles.container}>
      {/* Avatar + Name */}
      <View style={styles.top}>
        <ProfileAvatar profileUrl={profile.profileImage} size={64} />
        <View style={styles.nameBlock}>
          <Text style={styles.userName}>{profile.userName}</Text>
          {profile.userTitle ? (
            <Text style={styles.userTitle}>{profile.userTitle}</Text>
          ) : null}
        </View>
      </View>

      {/* Status message */}
      {profile.statusMessage ? (
        <View style={styles.statusBubble}>
          <Text style={styles.statusText} numberOfLines={3}>
            {profile.statusMessage}
          </Text>
        </View>
      ) : null}

      {/* Stats row */}
      <View style={styles.statsRow}>
        {stats.map((s) => (
          <Pressable
            key={s.label}
            style={styles.statItem}
            onPress={s.onPress}
            disabled={!s.onPress}
          >
            <Text style={styles.statValue}>{formatNumber(s.value)}</Text>
            <Text style={styles.statLabel}>{s.label}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.md,
  },
  top: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  nameBlock: {
    flex: 1,
  },
  userName: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.primary,
  },
  userTitle: {
    fontSize: 13,
    color: colors.hint,
    marginTop: 2,
  },
  statusBubble: {
    marginTop: 12,
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  statusText: {
    fontSize: 13,
    color: colors.primary,
    lineHeight: 18,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 16,
    paddingVertical: 12,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: colors.divider,
  },
  statItem: {
    alignItems: 'center',
    gap: 2,
  },
  statValue: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.primary,
  },
  statLabel: {
    fontSize: 11,
    color: colors.hint,
  },
});
