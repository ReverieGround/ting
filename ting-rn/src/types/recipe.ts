export interface RecipeImages {
  originalUrl: string;
  localPath: string;
}

export interface Ingredient {
  name: string;
  quantity: string;
}

export interface MethodImage {
  originalUrl: string;
  localPath: string;
}

export interface RecipeMethod {
  describe: string;
  image: MethodImage;
}

export interface Nutrition {
  calories: string;
  protein: string;
  carbohydrates: string;
  fat: string;
  sodium: string;
}

export interface Recipe {
  id: string;
  title: string;
  foodCategory: string;
  cookingCategory: string;
  images: RecipeImages;
  tags: string;
  tips: string;
  ingredients: Ingredient[];
  methods: RecipeMethod[];
  nutrition: Nutrition;
}

export function recipeToJson(recipe: Recipe): Record<string, unknown> {
  return {
    _id: recipe.id,
    title: recipe.title,
    food_category: recipe.foodCategory,
    cooking_category: recipe.cookingCategory,
    images: {
      original_url: recipe.images.originalUrl,
      local_path: recipe.images.localPath,
    },
    tags: recipe.tags,
    tips: recipe.tips,
    ingredients: recipe.ingredients.map((i) => ({
      name: i.name,
      quantity: i.quantity,
    })),
    methods: recipe.methods.map((m) => ({
      describe: m.describe,
      image: {
        original_url: m.image.originalUrl,
        local_path: m.image.localPath,
      },
    })),
    nutrition: {
      calories: recipe.nutrition.calories,
      protein: recipe.nutrition.protein,
      carbohydrates: recipe.nutrition.carbohydrates,
      fat: recipe.nutrition.fat,
      sodium: recipe.nutrition.sodium,
    },
  };
}

export function recipeFromJson(json: Record<string, unknown>): Recipe {
  const imgs = json.images as Record<string, string>;
  const nutr = json.nutrition as Record<string, string>;
  return {
    id: json._id as string,
    title: json.title as string,
    foodCategory: json.food_category as string,
    cookingCategory: json.cooking_category as string,
    images: { originalUrl: imgs.original_url, localPath: imgs.local_path },
    tags: json.tags as string,
    tips: json.tips as string,
    ingredients: (json.ingredients as Record<string, string>[]).map((i) => ({
      name: i.name,
      quantity: i.quantity,
    })),
    methods: (json.methods as Record<string, unknown>[]).map((m) => {
      const img = m.image as Record<string, string>;
      return {
        describe: m.describe as string,
        image: { originalUrl: img.original_url, localPath: img.local_path },
      };
    }),
    nutrition: {
      calories: nutr.calories,
      protein: nutr.protein,
      carbohydrates: nutr.carbohydrates,
      fat: nutr.fat,
      sodium: nutr.sodium,
    },
  };
}
