// lib/pages/RecipeDetailPage.dart (업데이트된 코드)

import 'package:flutter/material.dart';
import '../models/Recipe.dart';
import 'RecipeEditPage.dart';

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 메인 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              recipe.images.originalUrl, // images 객체에서 originalUrl 사용
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 200);
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // 레시피 팁
          Text(
            '💡 ${recipe.tips}',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // 영양 정보
          Text(
            '영양 정보',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 10),
          _buildNutritionInfo(),
          const SizedBox(height: 24),

          // 재료
          Text(
            '재료',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 10),
          ...recipe.ingredients.map((ingredient) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('• ${ingredient.name}: ${ingredient.quantity}'),
          )),
          const SizedBox(height: 24),

          // 요리 방법
          Text(
            '요리 방법',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 10),
          // methods 리스트를 순회하며 위젯 생성
          ...recipe.methods.map((method) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.describe,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      method.image.originalUrl, // method 객체 내의 image 객체 사용
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 150);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeEditPage(recipe: recipe),
                ),
              );
            },
            icon: const Icon(Icons.restaurant_menu, size: 24, color: Colors.black),
            label: const Text(
              '요리하고 공유하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onSurface,
              foregroundColor: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 영양 정보 위젯은 그대로 유지
  Widget _buildNutritionInfo() {
    return Column(
      children: [
        _buildNutritionRow('칼로리', '${recipe.nutrition.calories}kcal'),
        _buildNutritionRow('단백질', '${recipe.nutrition.protein}g'),
        _buildNutritionRow('탄수화물', '${recipe.nutrition.carbohydrates}g'),
        _buildNutritionRow('지방', '${recipe.nutrition.fat}g'),
        _buildNutritionRow('나트륨', '${recipe.nutrition.sodium}mg'),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}