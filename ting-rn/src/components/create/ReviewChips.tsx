import { ScrollView, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, radius } from '../../theme/colors';

const REVIEWS: { label: string; icon: keyof typeof Ionicons.glyphMap }[] = [
  { label: 'Fire', icon: 'flame-outline' },
  { label: 'Tasty', icon: 'heart-outline' },
  { label: 'Soso', icon: 'remove-outline' },
  { label: 'Woops', icon: 'alert-circle-outline' },
  { label: 'Wack', icon: 'thumbs-down-outline' },
];

interface Props {
  selected: string;
  onSelect: (value: string) => void;
}

export default function ReviewChips({ selected, onSelect }: Props) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.row}
    >
      {REVIEWS.map((r) => {
        const active = selected === r.label;
        return (
          <TouchableOpacity
            key={r.label}
            style={[styles.chip, active && styles.chipActive]}
            onPress={() => onSelect(active ? '' : r.label)}
          >
            <Ionicons
              name={r.icon}
              size={16}
              color={active ? colors.black : colors.primary}
            />
            <Text style={[styles.text, active && styles.textActive]}>
              {r.label}
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
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: radius.full,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  chipActive: {
    backgroundColor: '#C7F464',
  },
  icon: {
    marginRight: 2,
  },
  text: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.primary,
  },
  textActive: {
    color: colors.black,
  },
});
