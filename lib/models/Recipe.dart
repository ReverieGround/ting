// lib/models/recipe.dart (업데이트된 코드)

class Recipe {
  final String id;
  final String title;
  final String foodCategory;
  final String cookingCategory;
  final Images images;
  final String tags;
  final String tips;
  final List<Ingredient> ingredients;
  final List<Method> methods;
  final Nutrition nutrition;

  Recipe({
    required this.id,
    required this.title,
    required this.foodCategory,
    required this.cookingCategory,
    required this.images,
    required this.tags,
    required this.tips,
    required this.ingredients,
    required this.methods,
    required this.nutrition,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['_id'],
      title: json['title'],
      foodCategory: json['food_category'],
      cookingCategory: json['cooking_category'],
      images: Images.fromJson(json['images']),
      tags: json['tags'],
      tips: json['tips'],
      ingredients: (json['ingredients'] as List)
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      methods: (json['methods'] as List)
          .map((m) => Method.fromJson(m))
          .toList(),
      nutrition: Nutrition.fromJson(json['nutrition']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "title": title,
      "food_category": foodCategory,
      "cooking_category": cookingCategory,
      "images": images.toJson(),
      "tags": tags,
      "tips": tips,
      "ingredients": ingredients.map((i) => i.toJson()).toList(),
      "methods": methods.map((m) => m.toJson()).toList(),
      "nutrition": nutrition.toJson(),
    };
  }

}

class Images {
  final String originalUrl;
  final String localPath;

  Images({required this.originalUrl, required this.localPath});

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      originalUrl: json['original_url'],
      localPath: json['local_path'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "original_url": originalUrl,
      "local_path": localPath,
    };
  }
}

class Ingredient {
  final String name;
  final String quantity;

  Ingredient({required this.name, required this.quantity});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "quantity": quantity,
    };
  }
}

class Method {
  final String describe;
  final MethodImage image;

  Method({required this.describe, required this.image});

  factory Method.fromJson(Map<String, dynamic> json) {
    return Method(
      describe: json['describe'],
      image: MethodImage.fromJson(json['image']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "describe": describe,
      "image": image.toJson(),
    };
  }
}

class MethodImage {
  final String originalUrl;
  final String localPath;

  MethodImage({required this.originalUrl, required this.localPath});

  factory MethodImage.fromJson(Map<String, dynamic> json) {
    return MethodImage(
      originalUrl: json['original_url'],
      localPath: json['local_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "original_url": originalUrl,
      "local_path": localPath,
    };
  }
}

class Nutrition {
  final String calories;
  final String protein;
  final String carbohydrates;
  final String fat;
  final String sodium;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.sodium,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'],
      protein: json['protein'],
      carbohydrates: json['carbohydrates'],
      fat: json['fat'],
      sodium: json['sodium'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "calories": calories,
      "protein": protein,
      "carbohydrates": carbohydrates,
      "fat": fat,
      "sodium": sodium,
    };
  }
}