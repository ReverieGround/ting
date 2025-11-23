// lib/services/recipe_service.dart (업데이트된 코드)

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 최신 레시피를 가져오는 메서드
  Future<List<Recipe>> fetchLatestRecipes({
    required int limit,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final recipes = querySnapshot.docs.map((doc) {
        return Recipe.fromJson(doc.data());
      }).toList();

      return recipes;
    } catch (e) {
      debugPrint('Error fetching latest recipes: $e');
      rethrow;
    }
  }

  // 카테고리별 레시피를 가져오는 메서드
  Future<List<Recipe>> fetchRecipesByCategory({
    String? foodCategory,
    String? cookingCategory,
    required int limit,
  }) async {
    try {
      Query query = _firestore.collection('recipes');

      if (foodCategory != null && foodCategory.isNotEmpty) {
        query = query.where('food_category', isEqualTo: foodCategory);
      }

      if (cookingCategory != null && cookingCategory.isNotEmpty) {
        query = query.where('cooking_category', isEqualTo: cookingCategory);
      }
      
      final querySnapshot = await query
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final recipes = querySnapshot.docs.map((doc) {
        return Recipe.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      return recipes;
    } catch (e) {
      debugPrint('Error fetching recipes by category: $e');
      rethrow;
    }
  }
  
  // 특정 태그(재료)를 포함하는 레시피를 검색하는 메서드
  Future<List<Recipe>> searchRecipesByTag({
    required String tag,
    required int limit,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('tags', isEqualTo: tag)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final recipes = querySnapshot.docs.map((doc) {
        return Recipe.fromJson(doc.data());
      }).toList();

      return recipes;
    } catch (e) {
      debugPrint('Error searching recipes by tag: $e');
      rethrow;
    }
  }
}