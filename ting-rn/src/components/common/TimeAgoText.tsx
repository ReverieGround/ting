import { Text, StyleSheet } from 'react-native';
import { timeAgo } from '../../utils/formatTimestamp';

interface Props {
  createdAt: Date | { toDate: () => Date } | string;
  fontSize?: number;
  color?: string;
}

export function TimeAgoText({ createdAt, fontSize = 12, color = '#999' }: Props) {
  let date: Date;

  if (createdAt instanceof Date) {
    date = createdAt;
  } else if (typeof createdAt === 'object' && 'toDate' in createdAt) {
    date = createdAt.toDate();
  } else {
    date = new Date(createdAt as string);
  }

  return <Text style={[styles.text, { fontSize, color }]}>{timeAgo(date)}</Text>;
}

const styles = StyleSheet.create({
  text: {
    fontWeight: '400',
  },
});
