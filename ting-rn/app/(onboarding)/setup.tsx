import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  TouchableOpacity,
  Image,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import * as ImagePicker from 'expo-image-picker';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, radius } from '../../src/theme/colors';
import { authService } from '../../src/services/authService';
import { userService } from '../../src/services/userService';
import { useAuthStore } from '../../src/stores/authStore';

const COUNTRIES = [
  { code: 'KR', name: '대한민국' },
  { code: 'US', name: '미국' },
  { code: 'JP', name: '일본' },
] as const;

export default function OnboardingSetupPage() {
  const [nickname, setNickname] = useState('');
  const [countryCode, setCountryCode] = useState('KR');
  const [bio, setBio] = useState('');
  const [imageUri, setImageUri] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const setStatus = useAuthStore((s) => s.setStatus);

  const countryName =
    COUNTRIES.find((c) => c.code === countryCode)?.name ?? '대한민국';

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.9,
      allowsEditing: true,
      aspect: [1, 1],
    });
    if (!result.canceled && result.assets[0]) {
      setImageUri(result.assets[0].uri);
    }
  };

  const handleSubmit = async () => {
    const trimmed = nickname.trim();
    if (!trimmed) {
      Alert.alert('닉네임을 입력해주세요');
      return;
    }

    setSaving(true);
    try {
      await authService.saveIdToken();
      await authService.registerUser({
        userName: trimmed,
        countryCode,
        countryName,
        bio: bio.trim() || undefined,
      });

      if (imageUri) {
        await userService.uploadProfileImage(imageUri);
      }

      await authService.markHasLoggedInBefore();
      setStatus('authenticated');
    } catch (e) {
      console.error('Onboarding error:', e);
      Alert.alert('오류', '프로필 저장 중 오류가 발생했습니다.');
    } finally {
      setSaving(false);
    }
  };

  const handleSkip = () => {
    setStatus('authenticated');
  };

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
      >
        <Text style={styles.title}>첫 설정</Text>
        <Text style={styles.subtitle}>
          T!ng을 시작하려면 몇 가지만 설정해요. (1분)
        </Text>

        {/* Profile Image */}
        <TouchableOpacity
          style={styles.avatarWrap}
          onPress={pickImage}
          disabled={saving}
        >
          {imageUri ? (
            <Image source={{ uri: imageUri }} style={styles.avatar} />
          ) : (
            <View style={styles.avatarPlaceholder}>
              <Ionicons name="person" size={44} color={colors.hint} />
            </View>
          )}
          <View style={styles.cameraIcon}>
            <Ionicons name="camera" size={20} color={colors.white} />
          </View>
        </TouchableOpacity>

        {/* Nickname */}
        <Text style={styles.label}>닉네임 *</Text>
        <TextInput
          style={styles.input}
          value={nickname}
          onChangeText={setNickname}
          maxLength={20}
          placeholder="예: 맛잘알, 초보쿡"
          placeholderTextColor={colors.hint}
          editable={!saving}
        />

        {/* Country */}
        <Text style={styles.label}>국가/지역</Text>
        <View style={styles.pickerWrap}>
          <Picker
            selectedValue={countryCode}
            onValueChange={setCountryCode}
            style={styles.picker}
            dropdownIconColor={colors.primary}
            enabled={!saving}
          >
            {COUNTRIES.map((c) => (
              <Picker.Item
                key={c.code}
                label={`${c.name}`}
                value={c.code}
                color={Platform.OS === 'ios' ? colors.primary : undefined}
              />
            ))}
          </Picker>
        </View>

        {/* Bio */}
        <Text style={styles.label}>한 줄 소개</Text>
        <TextInput
          style={[styles.input, styles.bioInput]}
          value={bio}
          onChangeText={setBio}
          maxLength={80}
          placeholder="예: 자취생 3년차, 다이어트 레시피 수집가"
          placeholderTextColor={colors.hint}
          multiline
          editable={!saving}
        />

        {/* Submit */}
        <TouchableOpacity
          style={[styles.submitBtn, saving && styles.btnDisabled]}
          onPress={handleSubmit}
          disabled={saving}
        >
          {saving ? (
            <ActivityIndicator color={colors.onPrimary} />
          ) : (
            <Text style={styles.submitText}>시작하기</Text>
          )}
        </TouchableOpacity>

        {/* Skip */}
        <TouchableOpacity
          style={styles.skipBtn}
          onPress={handleSkip}
          disabled={saving}
        >
          <Text style={styles.skipText}>나중에 할래요</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.bgLight },
  container: { flex: 1, backgroundColor: colors.bgLight },
  content: { padding: spacing.lg, paddingTop: 60 },

  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: spacing.xs,
  },
  subtitle: {
    fontSize: 15,
    color: colors.hint,
    marginBottom: spacing.xl,
  },

  avatarWrap: {
    alignSelf: 'center',
    marginBottom: spacing.lg,
  },
  avatar: {
    width: 88,
    height: 88,
    borderRadius: 44,
  },
  avatarPlaceholder: {
    width: 88,
    height: 88,
    borderRadius: 44,
    backgroundColor: colors.border,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cameraIcon: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255,255,255,0.25)',
    justifyContent: 'center',
    alignItems: 'center',
  },

  label: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.primary,
    marginBottom: spacing.xs,
    marginTop: spacing.md,
  },
  input: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 14,
    padding: 14,
    fontSize: 16,
    color: colors.primary,
  },
  bioInput: {
    height: 72,
    textAlignVertical: 'top',
  },
  pickerWrap: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 14,
    overflow: 'hidden',
  },
  picker: {
    color: colors.primary,
  },

  submitBtn: {
    backgroundColor: colors.primary,
    borderRadius: radius.sm,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: spacing.xl,
  },
  btnDisabled: { opacity: 0.5 },
  submitText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.onPrimary,
  },

  skipBtn: {
    alignItems: 'center',
    paddingVertical: 14,
    marginTop: spacing.sm,
  },
  skipText: {
    fontSize: 14,
    color: colors.hint,
  },
});
