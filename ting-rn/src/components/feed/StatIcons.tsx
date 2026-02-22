import { View, Text, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../theme/colors';
import { formatNumber } from '../../utils/formatNumber';
import { useLike } from '../../hooks/useLike';

interface Props {
  postId: string;
  postOwnerId: string;
  likesCount: number;
  commentsCount: number;
  fontColor?: string;
  iconSize?: number;
  fontSize?: number;
}

export function StatIcons({
  postId,
  postOwnerId,
  likesCount,
  commentsCount,
  fontColor = colors.primary,
  iconSize = 20,
  fontSize = 14,
}: Props) {
  const { isLiked, toggle } = useLike(postId, postOwnerId);

  return (
    <View style={styles.container}>
      {/* Like / Cooking icon */}
      <Pressable style={styles.iconRow} onPress={toggle}>
        <Ionicons
          name={isLiked ? 'heart' : 'heart-outline'}
          size={iconSize}
          color={isLiked ? '#FF4444' : fontColor}
        />
        <Text style={[styles.count, { color: fontColor, fontSize }]}>
          {formatNumber(likesCount)}
        </Text>
      </Pressable>

      {/* Comment / Reply icon */}
      <View style={styles.iconRow}>
        <Ionicons name="chatbubble-outline" size={iconSize - 2} color={fontColor} />
        <Text style={[styles.count, { color: fontColor, fontSize }]}>
          {formatNumber(commentsCount)}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
    paddingVertical: 4,
    gap: 12,
  },
  iconRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  count: {
    fontWeight: '500',
  },
});
