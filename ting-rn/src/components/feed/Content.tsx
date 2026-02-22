import { View, Text, StyleSheet } from 'react-native';
import { colors } from '../../theme/colors';

interface Props {
  content?: string;
  fontColor?: string;
}

export function Content({ content, fontColor = colors.primary }: Props) {
  if (!content) return null;

  return (
    <View style={styles.container}>
      <Text style={[styles.text, { color: fontColor }]}>{content}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  text: {
    fontSize: 16,
    lineHeight: 22,
  },
});
