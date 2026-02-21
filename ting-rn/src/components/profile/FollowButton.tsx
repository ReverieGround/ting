import { Pressable, Text, ActivityIndicator, StyleSheet } from 'react-native';
import { useFollow } from '../../hooks/useFollow';
import { colors } from '../../theme/colors';

interface Props {
  targetUid: string;
  width?: number;
  height?: number;
}

export function FollowButton({ targetUid, width = 343, height = 40 }: Props) {
  const { isFollowing, loading, toggle } = useFollow(targetUid);

  if (loading) {
    return (
      <Pressable style={[styles.button, styles.loading, { width, height }]} disabled>
        <ActivityIndicator size="small" color={colors.primary} />
      </Pressable>
    );
  }

  return (
    <Pressable
      style={[
        styles.button,
        isFollowing ? styles.following : styles.notFollowing,
        { width, height },
      ]}
      onPress={toggle}
    >
      <Text
        style={[
          styles.text,
          { color: isFollowing ? colors.primary : colors.onPrimary },
        ]}
      >
        {isFollowing ? '팔로잉' : '팔로우'}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    alignSelf: 'center',
  },
  following: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: colors.border,
  },
  notFollowing: {
    backgroundColor: colors.primary,
  },
  loading: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: colors.border,
  },
  text: {
    fontSize: 14,
    fontWeight: '600',
  },
});
