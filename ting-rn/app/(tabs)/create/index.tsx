import { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Switch,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { router } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, radius } from '../../../src/theme/colors';
import CategoryChips from '../../../src/components/create/CategoryChips';
import ReviewChips from '../../../src/components/create/ReviewChips';
import PostTextField from '../../../src/components/create/PostTextField';
import LinkInputRow from '../../../src/components/create/LinkInputRow';
import DatePickerButton from '../../../src/components/create/DatePickerButton';

export default function CreatePostPage() {
  const [imageUris, setImageUris] = useState<string[]>([]);
  const [category, setCategory] = useState('');
  const [review, setReview] = useState('');
  const [content, setContent] = useState('');
  const [capturedDate, setCapturedDate] = useState(new Date());
  const [recommendRecipe, setRecommendRecipe] = useState(false);
  const [mealKitLink, setMealKitLink] = useState('');
  const [restaurantName, setRestaurantName] = useState('');
  const [deliveryLink, setDeliveryLink] = useState('');

  const pickImages = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.9,
      allowsMultipleSelection: true,
      selectionLimit: 10,
    });
    if (!result.canceled && result.assets.length > 0) {
      setImageUris((prev) => [
        ...prev,
        ...result.assets.map((a) => a.uri),
      ]);
    }
  };

  const removeImage = (index: number) => {
    setImageUris((prev) => prev.filter((_, i) => i !== index));
  };

  const handleNext = () => {
    if (imageUris.length === 0) {
      Alert.alert('이미지를 선택해주세요');
      return;
    }
    if (!category) {
      Alert.alert('카테고리를 선택해주세요');
      return;
    }
    if (!review) {
      Alert.alert('리뷰를 선택해주세요');
      return;
    }
    if (!content.trim()) {
      Alert.alert('내용을 입력해주세요');
      return;
    }

    router.push({
      pathname: '/(tabs)/create/confirm',
      params: {
        imageUris: JSON.stringify(imageUris),
        category,
        review,
        content: content.trim(),
        capturedDate: capturedDate.toISOString(),
        recommendRecipe: recommendRecipe ? '1' : '0',
        mealKitLink,
        restaurantName,
        deliveryLink,
      },
    });
  };

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>기록</Text>
        </View>

        {/* Date */}
        <DatePickerButton date={capturedDate} onDateChange={setCapturedDate} />

        {/* Images */}
        <View style={styles.imagesSection}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.imageRow}
          >
            {imageUris.map((uri, i) => (
              <View key={uri + i} style={styles.imageWrap}>
                <Image source={{ uri }} style={styles.imageThumb} />
                <TouchableOpacity
                  style={styles.removeBtn}
                  onPress={() => removeImage(i)}
                >
                  <Ionicons name="close-circle" size={22} color="rgba(255,255,255,0.8)" />
                </TouchableOpacity>
              </View>
            ))}
            <TouchableOpacity style={styles.addImageBtn} onPress={pickImages}>
              <Ionicons name="add" size={32} color={colors.hint} />
            </TouchableOpacity>
          </ScrollView>
        </View>

        {/* Category */}
        <Text style={styles.sectionLabel}>카테고리</Text>
        <CategoryChips selected={category} onSelect={setCategory} />

        {/* Review */}
        <Text style={[styles.sectionLabel, { marginTop: spacing.md }]}>리뷰</Text>
        <ReviewChips selected={review} onSelect={setReview} />

        {/* Conditional sections */}
        {category === '요리' && (
          <View style={styles.conditionalSection}>
            <View style={styles.toggleRow}>
              <Text style={styles.toggleLabel}>레시피 추천</Text>
              <Switch
                value={recommendRecipe}
                onValueChange={setRecommendRecipe}
                trackColor={{ true: '#C7F464', false: 'rgba(255,255,255,0.15)' }}
                thumbColor={colors.white}
              />
            </View>
          </View>
        )}
        {category === '밀키트' && (
          <View style={styles.conditionalSection}>
            <Text style={styles.conditionalLabel}>구매 링크</Text>
            <LinkInputRow
              value={mealKitLink}
              onChangeText={setMealKitLink}
              placeholder="밀키트 구매 링크를 입력하세요"
              icon="cart-outline"
            />
          </View>
        )}
        {category === '식당' && (
          <View style={styles.conditionalSection}>
            <Text style={styles.conditionalLabel}>식당명</Text>
            <LinkInputRow
              value={restaurantName}
              onChangeText={setRestaurantName}
              placeholder="식당 이름을 입력하세요"
              icon="restaurant-outline"
            />
          </View>
        )}
        {category === '배달' && (
          <View style={styles.conditionalSection}>
            <Text style={styles.conditionalLabel}>배달 링크</Text>
            <LinkInputRow
              value={deliveryLink}
              onChangeText={setDeliveryLink}
              placeholder="배달 앱 링크를 입력하세요"
              icon="bicycle-outline"
            />
          </View>
        )}

        {/* Content */}
        <Text style={[styles.sectionLabel, { marginTop: spacing.md }]}>내용</Text>
        <PostTextField value={content} onChangeText={setContent} />

        {/* Next button */}
        <TouchableOpacity style={styles.nextBtn} onPress={handleNext}>
          <Text style={styles.nextText}>다음</Text>
          <Ionicons name="arrow-forward" size={18} color={colors.onPrimary} />
        </TouchableOpacity>

        <View style={{ height: 100 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.bgLight },
  container: { flex: 1, backgroundColor: colors.bgLight },
  scrollContent: { paddingTop: 60 },

  header: {
    paddingHorizontal: spacing.md,
    paddingBottom: spacing.sm,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.primary,
  },

  imagesSection: {
    marginTop: spacing.sm,
  },
  imageRow: {
    paddingHorizontal: spacing.md,
    gap: spacing.sm,
  },
  imageWrap: {
    position: 'relative',
  },
  imageThumb: {
    width: 120,
    height: 120,
    borderRadius: radius.sm,
  },
  removeBtn: {
    position: 'absolute',
    top: 4,
    right: 4,
  },
  addImageBtn: {
    width: 120,
    height: 120,
    borderRadius: radius.sm,
    backgroundColor: 'rgba(255,255,255,0.08)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
    borderStyle: 'dashed',
  },

  sectionLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.primary,
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
    paddingHorizontal: spacing.md,
  },

  conditionalSection: {
    marginTop: spacing.md,
  },
  conditionalLabel: {
    fontSize: 13,
    color: colors.hint,
    paddingHorizontal: spacing.md,
    marginBottom: spacing.xs,
  },
  toggleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing.md,
  },
  toggleLabel: {
    fontSize: 15,
    color: colors.primary,
  },

  nextBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: colors.primary,
    marginHorizontal: spacing.md,
    marginTop: spacing.xl,
    paddingVertical: 16,
    borderRadius: radius.sm,
  },
  nextText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.onPrimary,
  },
});
