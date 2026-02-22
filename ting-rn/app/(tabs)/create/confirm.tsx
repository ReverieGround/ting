import { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { Picker } from '@react-native-picker/picker';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, radius } from '../../../src/theme/colors';
import { storageService } from '../../../src/services/storageService';
import { postService } from '../../../src/services/postService';
import { userService } from '../../../src/services/userService';
import { Visibility } from '../../../src/types/post';

export default function ConfirmPostPage() {
  const params = useLocalSearchParams<{
    imageUris: string;
    category: string;
    review: string;
    content: string;
    capturedDate: string;
    recommendRecipe: string;
    mealKitLink: string;
    restaurantName: string;
    deliveryLink: string;
  }>();

  const imageUris: string[] = JSON.parse(params.imageUris || '[]');
  const [visibility, setVisibility] = useState<Visibility>('PUBLIC');
  const [uploading, setUploading] = useState(false);

  const handleUpload = async () => {
    setUploading(true);
    try {
      const uploadedUrls = await storageService.uploadPostImages(imageUris);
      if (uploadedUrls.length === 0) {
        Alert.alert('오류', '이미지 업로드에 실패했습니다.');
        return;
      }

      const region = await userService.fetchUserRegion();

      const title = buildTitle(params.category, params.review);

      // Graceful date parsing (matches Flutter's try-catch on DateFormat.parse)
      let capturedAt: Date | undefined;
      try {
        const d = new Date(params.capturedDate);
        if (!isNaN(d.getTime())) capturedAt = d;
      } catch {
        // Fall back to server timestamp
      }

      const postId = await postService.createPost({
        title,
        content: params.content,
        imageUrls: uploadedUrls,
        visibility,
        category: params.category,
        value: params.review,
        region: region ?? undefined,
        capturedAt,
      });

      if (postId) {
        Alert.alert('업로드 완료', '게시글이 등록되었습니다.');
        router.replace('/(tabs)/feed');
      } else {
        Alert.alert('오류', '게시글 생성에 실패했습니다.');
      }
    } catch (e) {
      console.error('Upload error:', e);
      Alert.alert('오류', '업로드 중 오류가 발생했습니다.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
    >
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color={colors.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>업로드 확인</Text>
        <View style={{ width: 24 }} />
      </View>

      {/* Image preview stack */}
      <View style={styles.previewSection}>
        {imageUris.length > 0 && (
          <View style={styles.stackWrap}>
            {imageUris.slice(0, 3).map((uri, i) => (
              <Image
                key={uri + i}
                source={{ uri }}
                style={[
                  styles.stackImage,
                  {
                    transform: [
                      { rotate: `${(i - 1) * 3}deg` },
                      { translateY: i * 2 },
                    ],
                    zIndex: 3 - i,
                  },
                ]}
              />
            ))}
            {imageUris.length > 3 && (
              <View style={styles.moreOverlay}>
                <Text style={styles.moreText}>+{imageUris.length - 3}</Text>
              </View>
            )}
          </View>
        )}
      </View>

      {/* Summary */}
      <View style={styles.summarySection}>
        <SummaryRow label="카테고리" value={params.category} />
        <SummaryRow label="리뷰" value={params.review} />
        <SummaryRow label="이미지" value={`${imageUris.length}장`} />
        <SummaryRow
          label="내용"
          value={
            params.content.length > 40
              ? params.content.slice(0, 40) + '...'
              : params.content
          }
        />
      </View>

      {/* Visibility */}
      <Text style={styles.sectionLabel}>공개범위</Text>
      <View style={styles.pickerWrap}>
        <Picker
          selectedValue={visibility}
          onValueChange={(v) => setVisibility(v)}
          style={styles.picker}
          dropdownIconColor={colors.primary}
        >
          <Picker.Item label="전체 공개" value="PUBLIC" color={colors.primary} />
          <Picker.Item label="내 친구만" value="FOLLOWER" color={colors.primary} />
          <Picker.Item label="비공개" value="PRIVATE" color={colors.primary} />
        </Picker>
      </View>

      {/* Upload button */}
      <TouchableOpacity
        style={[styles.uploadBtn, uploading && styles.btnDisabled]}
        onPress={handleUpload}
        disabled={uploading}
      >
        {uploading ? (
          <ActivityIndicator color={colors.onPrimary} />
        ) : (
          <>
            <Ionicons name="cloud-upload-outline" size={20} color={colors.onPrimary} />
            <Text style={styles.uploadText}>업로드</Text>
          </>
        )}
      </TouchableOpacity>
    </ScrollView>
  );
}

function SummaryRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.summaryRow}>
      <Text style={styles.summaryLabel}>{label}</Text>
      <Text style={styles.summaryValue}>{value}</Text>
    </View>
  );
}

function buildTitle(category: string, review: string): string {
  return `${category} - ${review}`;
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bgLight },
  content: { paddingTop: 60, paddingBottom: 100 },

  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.md,
    paddingBottom: spacing.md,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.primary,
  },

  previewSection: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  stackWrap: {
    width: 200,
    height: 200,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stackImage: {
    position: 'absolute',
    width: 160,
    height: 160,
    borderRadius: radius.md,
  },
  moreOverlay: {
    position: 'absolute',
    right: 10,
    bottom: 10,
    backgroundColor: 'rgba(0,0,0,0.6)',
    borderRadius: radius.full,
    width: 36,
    height: 36,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  moreText: {
    color: colors.white,
    fontSize: 13,
    fontWeight: '600',
  },

  summarySection: {
    marginHorizontal: spacing.md,
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: radius.sm,
    padding: spacing.md,
    gap: spacing.sm,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  summaryLabel: {
    fontSize: 14,
    color: colors.hint,
  },
  summaryValue: {
    fontSize: 14,
    color: colors.primary,
    fontWeight: '500',
    flexShrink: 1,
    textAlign: 'right',
    marginLeft: spacing.md,
  },

  sectionLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.primary,
    marginTop: spacing.lg,
    marginBottom: spacing.xs,
    paddingHorizontal: spacing.md,
  },
  pickerWrap: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: radius.sm,
    marginHorizontal: spacing.md,
    overflow: 'hidden',
  },
  picker: {
    color: colors.primary,
  },

  uploadBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: 'rgb(255,110,199)',
    borderWidth: 1,
    borderColor: 'rgb(255,110,199)',
    marginHorizontal: 20,
    marginTop: spacing.xl,
    paddingVertical: 12,
    borderRadius: 30,
  },
  btnDisabled: { opacity: 0.5 },
  uploadText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#FFFFFF',
  },
});
