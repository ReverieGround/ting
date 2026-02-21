import { View, Text, StyleSheet } from 'react-native';
import { colors, spacing } from '../../src/theme/colors';

export default function OnboardingSetupPage() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>프로필 설정</Text>
      <Text style={styles.subtitle}>
        닉네임, 국가, 바이오를 설정해주세요
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bgLight,
    padding: spacing.lg,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: spacing.sm,
  },
  subtitle: {
    fontSize: 16,
    color: colors.hint,
  },
});
