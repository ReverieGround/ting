import firestore from '@react-native-firebase/firestore';
import { Recipe, recipeFromJson } from '../types/recipe';

export const recipeService = {
  async fetchLatestRecipes(params: { limit: number }): Promise<Recipe[]> {
    const snap = await firestore()
      .collection('recipes')
      .orderBy('created_at', 'desc')
      .limit(params.limit)
      .get();
    if (snap.empty) return [];
    return snap.docs.map((d) =>
      recipeFromJson(d.data() as Record<string, unknown>),
    );
  },

  async fetchRecipesByCategory(params: {
    foodCategory?: string;
    cookingCategory?: string;
    limit: number;
  }): Promise<Recipe[]> {
    let q: ReturnType<ReturnType<typeof firestore>['collection']> | any =
      firestore().collection('recipes');

    if (params.foodCategory) {
      q = q.where('food_category', '==', params.foodCategory);
    }
    if (params.cookingCategory) {
      q = q.where('cooking_category', '==', params.cookingCategory);
    }

    const snap = await q
      .orderBy('created_at', 'desc')
      .limit(params.limit)
      .get();
    if (snap.empty) return [];
    return snap.docs.map((d: any) =>
      recipeFromJson(d.data() as Record<string, unknown>),
    );
  },

  async searchRecipesByTag(params: {
    tag: string;
    limit: number;
  }): Promise<Recipe[]> {
    const snap = await firestore()
      .collection('recipes')
      .where('tags', '==', params.tag)
      .limit(params.limit)
      .get();
    if (snap.empty) return [];
    return snap.docs.map((d) =>
      recipeFromJson(d.data() as Record<string, unknown>),
    );
  },
};
