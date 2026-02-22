import { ScrollView, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { colors, spacing, radius } from '../../theme/colors';

const CATEGORIES = ['요리', '밀키트', '식당', '배달'];

interface Props {
  selected: string;
  onSelect: (category: string) => void;
}

export default function CategoryChips({ selected, onSelect }: Props) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.row}
    >
      {CATEGORIES.map((cat) => {
        const active = selected === cat;
        return (
          <TouchableOpacity
            key={cat}
            style={[styles.chip, active && styles.chipActive]}
            onPress={() => onSelect(active ? '' : cat)}
          >
            <Text style={[styles.text, active && styles.textActive]}>
              {cat}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  row: { gap: spacing.sm, paddingHorizontal: spacing.md },
  chip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: radius.full,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  chipActive: {
    backgroundColor: '#C7F464',
  },
  text: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.primary,
  },
  textActive: {
    color: colors.black,
  },
});
