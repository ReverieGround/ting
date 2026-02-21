import { View, Text, StyleSheet } from 'react-native';
import { Image } from 'expo-image';

const VALUE_ICONS: Record<string, any> = {
  // TODO: add actual asset images when available
  // 'Fire': require('../../../assets/fire.png'),
  // 'Tasty': require('../../../assets/tasty.png'),
};

interface Props {
  label: string;
  backgroundColor?: string;
  textColor?: string;
  fontSize?: number;
}

export function Tag({
  label,
  backgroundColor = 'rgba(255,255,255,0.7)',
  textColor = '#000',
  fontSize = 14,
}: Props) {
  const icon = VALUE_ICONS[label];

  return (
    <View style={[styles.container, { backgroundColor }]}>
      {icon && (
        <Image source={icon} style={styles.icon} contentFit="contain" />
      )}
      <Text style={[styles.text, { color: textColor, fontSize }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderWidth: 0.5,
    borderColor: '#000',
    gap: 4,
  },
  icon: {
    width: 16,
    height: 16,
  },
  text: {
    fontWeight: '500',
  },
});
