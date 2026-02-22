import { TextInput, StyleSheet } from 'react-native';
import { colors, spacing, radius } from '../../theme/colors';

interface Props {
  value: string;
  onChangeText: (text: string) => void;
}

export default function PostTextField({ value, onChangeText }: Props) {
  return (
    <TextInput
      style={styles.input}
      value={value}
      onChangeText={onChangeText}
      placeholder="오늘의 한 줄을 남겨주세요..."
      placeholderTextColor={colors.hint}
      multiline
      numberOfLines={4}
      textAlignVertical="top"
    />
  );
}

const styles = StyleSheet.create({
  input: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: radius.sm,
    padding: 14,
    fontSize: 15,
    color: colors.primary,
    minHeight: 100,
    marginHorizontal: spacing.md,
  },
});
