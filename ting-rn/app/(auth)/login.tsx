import { useState } from 'react';
import { View, Text, StyleSheet, Pressable, Alert, ActivityIndicator } from 'react-native';
import { colors, spacing, radius } from '../../src/theme/colors';
import { authService } from '../../src/services/authService';

export default function LoginPage() {
  const [loading, setLoading] = useState(false);

  const handleGoogleSignIn = async () => {
    setLoading(true);
    try {
      const ok = await authService.signInWithGoogle();
      if (!ok) {
        Alert.alert('로그인 실패', 'Google 로그인에 실패했습니다. 다시 시도해주세요.');
      }
    } catch {
      Alert.alert('오류', '로그인 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>T!ng</Text>
      <Text style={styles.subtitle}>소셜 푸드 커뮤니티</Text>

      <View style={styles.buttons}>
        <Pressable
          style={[styles.button, styles.google]}
          onPress={handleGoogleSignIn}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={colors.white} />
          ) : (
            <Text style={styles.buttonText}>Google로 계속하기</Text>
          )}
        </Pressable>

        {/* Facebook, Kakao, Naver — 추후 구현 예정
        <Pressable style={[styles.button, styles.facebook]}>
          <Text style={styles.buttonText}>Facebook으로 계속하기</Text>
        </Pressable>

        <Pressable style={[styles.button, styles.disabled]} disabled>
          <Text style={[styles.buttonText, styles.disabledText]}>
            Kakao (준비중)
          </Text>
        </Pressable>

        <Pressable style={[styles.button, styles.disabled]} disabled>
          <Text style={[styles.buttonText, styles.disabledText]}>
            Naver (준비중)
          </Text>
        </Pressable>
        */}
      </View>
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
    fontSize: 48,
    fontWeight: '800',
    color: colors.primary,
    marginBottom: spacing.sm,
  },
  subtitle: {
    fontSize: 16,
    color: colors.hint,
    marginBottom: spacing.xl * 2,
  },
  buttons: {
    width: '100%',
    gap: spacing.md,
  },
  button: {
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: colors.divider,
    backgroundColor: 'transparent',
  },
  google: {},
  facebook: {
    backgroundColor: '#1877F2',
  },
  disabled: {
    backgroundColor: 'rgba(234,236,239,0.1)',
  },
  buttonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: '600',
  },
  disabledText: {
    color: colors.hint,
  },
});
