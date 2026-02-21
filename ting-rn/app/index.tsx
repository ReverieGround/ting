import { useEffect } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { colors } from '../src/theme/colors';
import { useAuthStore } from '../src/stores/authStore';

export default function Index() {
  const router = useRouter();
  const status = useAuthStore((s) => s.status);
  const bootstrap = useAuthStore((s) => s.bootstrap);

  useEffect(() => {
    bootstrap();
  }, [bootstrap]);

  useEffect(() => {
    switch (status) {
      case 'unauthenticated':
        router.replace('/(auth)/login');
        break;
      case 'needsOnboarding':
        router.replace('/(onboarding)/setup');
        break;
      case 'authenticated':
        router.replace('/(tabs)/feed');
        break;
      // 'initializing' — show spinner
    }
  }, [status, router]);

  return (
    <View style={styles.container}>
      <ActivityIndicator size="large" color={colors.primary} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bgLight,
  },
});
