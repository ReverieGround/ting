import { useQuery } from '@tanstack/react-query';
import { recipeService } from '../services/recipeService';

export function useLatestRecipes(limit = 20) {
  return useQuery({
    queryKey: ['recipes', 'latest', limit],
    queryFn: () => recipeService.fetchLatestRecipes({ limit }),
  });
}

export function useRecipesByCategory(params: {
  foodCategory?: string;
  cookingCategory?: string;
  limit?: number;
}) {
  const limit = params.limit ?? 20;
  return useQuery({
    queryKey: ['recipes', 'category', params.foodCategory, params.cookingCategory, limit],
    queryFn: () =>
      recipeService.fetchRecipesByCategory({
        foodCategory: params.foodCategory,
        cookingCategory: params.cookingCategory,
        limit,
      }),
  });
}

export function useRecipeSearch(tag: string, limit = 20) {
  return useQuery({
    queryKey: ['recipes', 'search', tag, limit],
    queryFn: () => recipeService.searchRecipesByTag({ tag, limit }),
    enabled: tag.length > 0,
  });
}
