import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, radius } from '../../../src/theme/colors';
import { Recipe } from '../../../src/types/recipe';

export default function RecipeDetailPage() {
  const { recipe: recipeJson } = useLocalSearchParams<{ recipe: string }>();

  let recipe: Recipe | null = null;
  try {
    recipe = recipeJson ? JSON.parse(recipeJson) : null;
  } catch {
    recipe = null;
  }

  if (!recipe) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>레시피를 불러올 수 없습니다.</Text>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.backLink}>뒤로 가기</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleCookAndShare = () => {
    router.push({
      pathname: '/(tabs)/recipes/edit',
      params: { recipe: recipeJson },
    });
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()}>
            <Ionicons name="arrow-back" size={24} color={colors.primary} />
          </TouchableOpacity>
          <Text style={styles.title} numberOfLines={1}>
            {recipe.title}
          </Text>
          <View style={{ width: 24 }} />
        </View>

        {/* Main Image — borderRadius 12 matching Flutter */}
        {recipe.images.originalUrl ? (
          <Image
            source={{ uri: recipe.images.originalUrl }}
            style={styles.mainImage}
          />
        ) : null}

        {/* Tips — fontSize 16, grey color matching Flutter */}
        {recipe.tips ? (
          <View style={styles.section}>
            <View style={styles.tipsRow}>
              <Ionicons name="bulb-outline" size={16} color="#9E9E9E" />
              <Text style={styles.tipsText}>{recipe.tips}</Text>
            </View>
          </View>
        ) : null}

        {/* Nutrition */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>영양 정보</Text>
          <View style={styles.divider} />
          <NutritionRow label="칼로리" value={`${recipe.nutrition.calories}kcal`} />
          <NutritionRow label="단백질" value={`${recipe.nutrition.protein}g`} />
          <NutritionRow label="탄수화물" value={`${recipe.nutrition.carbohydrates}g`} />
          <NutritionRow label="지방" value={`${recipe.nutrition.fat}g`} />
          <NutritionRow label="나트륨" value={`${recipe.nutrition.sodium}mg`} />
        </View>

        {/* Ingredients */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>재료</Text>
          <View style={styles.divider} />
          {recipe.ingredients.map((ing, i) => (
            <Text key={i} style={styles.ingredientText}>
              • {ing.name}: {ing.quantity}
            </Text>
          ))}
        </View>

        {/* Methods — no step numbers, matching Flutter */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>요리 방법</Text>
          <View style={styles.divider} />
          {recipe.methods.map((method, i) => (
            <View key={i} style={styles.methodCard}>
              <Text style={styles.methodText}>{method.describe}</Text>
              {method.image?.originalUrl ? (
                <Image
                  source={{ uri: method.image.originalUrl }}
                  style={styles.methodImage}
                />
              ) : null}
            </View>
          ))}
        </View>

        <View style={{ height: 100 }} />
      </ScrollView>

      {/* Bottom CTA — icon size 24, borderRadius 12 matching Flutter */}
      <View style={styles.bottomBar}>
        <TouchableOpacity style={styles.ctaBtn} onPress={handleCookAndShare}>
          <Ionicons name="restaurant" size={24} color={colors.onPrimary} />
          <Text style={styles.ctaText}>요리하고 공유하기</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

function NutritionRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.nutritionRow}>
      <Text style={styles.nutritionLabel}>{label}</Text>
      <Text style={styles.nutritionValue}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bgLight },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bgLight,
  },
  content: { padding: spacing.md, paddingTop: 60 },

  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: spacing.md,
  },
  title: {
    flex: 1,
    fontSize: 18,
    fontWeight: '700',
    color: colors.primary,
    textAlign: 'center',
    marginHorizontal: spacing.sm,
  },

  // Main image — borderRadius 12 matching Flutter
  mainImage: {
    width: '100%',
    height: 200,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },

  section: {
    paddingTop: spacing.lg,
  },
  // Section title — headlineSmall equivalent
  sectionTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: spacing.xs,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: colors.divider,
    marginBottom: spacing.sm,
  },

  tipsRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 6,
  },
  tipsText: {
    flex: 1,
    fontSize: 16,
    color: '#9E9E9E',
    fontStyle: 'italic',
    lineHeight: 22,
  },

  nutritionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 4,
  },
  nutritionLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.primary,
  },
  nutritionValue: {
    fontSize: 14,
    color: colors.primary,
  },

  ingredientText: {
    fontSize: 14,
    color: colors.primary,
    paddingVertical: 4,
  },

  methodCard: {
    marginBottom: spacing.md,
  },
  // Method text — fontSize 16 matching Flutter, no step labels
  methodText: {
    fontSize: 16,
    color: colors.primary,
    lineHeight: 24,
    marginBottom: spacing.sm,
  },
  methodImage: {
    width: '100%',
    borderRadius: 8,
    aspectRatio: 16 / 9,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },

  // Bottom CTA — borderRadius 12 matching Flutter
  bottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: spacing.md,
    paddingBottom: 34,
    backgroundColor: 'rgba(15,17,21,0.95)',
  },
  ctaBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: colors.primary,
    paddingVertical: 16,
    borderRadius: 12,
  },
  ctaText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.onPrimary,
  },

  errorText: {
    fontSize: 16,
    color: colors.hint,
    marginBottom: spacing.sm,
  },
  backLink: {
    fontSize: 14,
    color: '#C7F464',
  },
});
