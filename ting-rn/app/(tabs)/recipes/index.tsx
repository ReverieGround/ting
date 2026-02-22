import { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Image,
  ActivityIndicator,
} from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, radius } from '../../../src/theme/colors';
import { recipeService } from '../../../src/services/recipeService';
import { Recipe } from '../../../src/types/recipe';

export default function RecipeListPage() {
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadRecipes();
  }, []);

  const loadRecipes = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await recipeService.fetchLatestRecipes({ limit: 20 });
      setRecipes(data);
    } catch (e) {
      console.error('Recipe fetch error:', e);
      setError('레시피를 불러올 수 없습니다.');
    } finally {
      setLoading(false);
    }
  };

  const renderItem = ({ item }: { item: Recipe }) => (
    <TouchableOpacity
      style={styles.card}
      onPress={() =>
        router.push({
          pathname: '/(tabs)/recipes/[recipeId]',
          params: { recipeId: item.id, recipe: JSON.stringify(item) },
        })
      }
      activeOpacity={0.7}
    >
      <Image
        source={{ uri: item.images.originalUrl }}
        style={styles.cardImage}
        defaultSource={undefined}
      />
      <View style={styles.cardContent}>
        <Text style={styles.cardTitle} numberOfLines={1}>
          {item.title}
        </Text>
        {item.tips ? (
          <Text style={styles.cardTips} numberOfLines={2}>
            {item.tips}
          </Text>
        ) : null}
      </View>
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <Ionicons name="alert-circle-outline" size={40} color={colors.hint} />
        <Text style={styles.emptyText}>{error}</Text>
        <TouchableOpacity onPress={loadRecipes} style={styles.retryBtn}>
          <Text style={styles.retryText}>다시 시도</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (recipes.length === 0) {
    return (
      <View style={styles.center}>
        <Ionicons name="book-outline" size={40} color={colors.hint} />
        <Text style={styles.emptyText}>데이터가 없습니다.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Ting List</Text>
      </View>
      <FlatList
        data={recipes}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.list}
      />
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
    gap: spacing.sm,
  },
  header: {
    paddingTop: 60,
    paddingHorizontal: spacing.md,
    paddingBottom: spacing.sm,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.primary,
  },
  list: {
    paddingHorizontal: spacing.md,
    paddingBottom: 100,
  },

  card: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: radius.sm,
    marginBottom: spacing.sm,
    overflow: 'hidden',
  },
  cardImage: {
    width: 150,
    height: 100,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  cardContent: {
    flex: 1,
    padding: spacing.sm,
    justifyContent: 'center',
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: 4,
  },
  cardTips: {
    fontSize: 12,
    color: colors.hint,
    lineHeight: 18,
  },

  emptyText: {
    fontSize: 15,
    color: colors.hint,
  },
  retryBtn: {
    marginTop: spacing.sm,
    paddingHorizontal: 20,
    paddingVertical: 8,
    borderRadius: radius.sm,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  retryText: {
    color: colors.primary,
    fontSize: 14,
  },
});
