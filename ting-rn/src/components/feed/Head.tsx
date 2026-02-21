import { View, Text, Pressable, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ProfileAvatar } from '../common/ProfileAvatar';
import { TimeAgoText } from '../common/TimeAgoText';
import { colors } from '../../theme/colors';

interface Props {
  profileImageUrl?: string | null;
  userName: string;
  userId: string;
  userTitle?: string;
  createdAt: Date | { toDate: () => Date } | string;
  fontColor?: string;
  isMine?: boolean;
  onEdit?: () => void;
  /** Render over image with transparent bg */
  overlay?: boolean;
}

export function Head({
  profileImageUrl,
  userName,
  userId,
  userTitle,
  createdAt,
  fontColor = colors.primary,
  isMine = false,
  onEdit,
  overlay = false,
}: Props) {
  const router = useRouter();

  return (
    <View style={[styles.container, overlay && styles.overlay]}>
      <Pressable
        style={styles.left}
        onPress={() => router.push(`/(tabs)/profile/${userId}`)}
      >
        <ProfileAvatar profileUrl={profileImageUrl} size={32} />
        <View style={styles.nameBlock}>
          <Text style={[styles.userName, { color: fontColor }]} numberOfLines={1}>
            {userName}
          </Text>
          {userTitle ? (
            <Text style={[styles.userTitle, { color: fontColor }]} numberOfLines={1}>
              {userTitle}
            </Text>
          ) : null}
        </View>
      </Pressable>

      <View style={styles.right}>
        <TimeAgoText
          createdAt={createdAt}
          fontSize={11}
          color={overlay ? 'rgba(255,255,255,0.8)' : '#999'}
        />
        {isMine && onEdit && (
          <Pressable onPress={onEdit} hitSlop={8}>
            <Ionicons name="ellipsis-vertical" size={18} color={fontColor} />
          </Pressable>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    backgroundColor: 'transparent',
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  nameBlock: {
    flex: 1,
  },
  userName: {
    fontSize: 14,
    fontWeight: '600',
  },
  userTitle: {
    fontSize: 11,
    opacity: 0.7,
  },
  right: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
});
