import 'package:flutter/material.dart';

class RecipePage extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipePage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final ingredients = List<Map<String, dynamic>>.from(recipe['ingredients']);
    final methods = Map<String, dynamic>.from(recipe['methods']);
    final nutrition = Map<String, dynamic>.from(recipe['nutrition']);
    final imageUrl = recipe['images']?['original_url'] ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                width: double.infinity, 
                color: Color.fromARGB(100, 250, 250, 250), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      recipe['title'], 
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 18
                      ),
                    ),
                  ],
                )
              ),
              background: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade200),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _section("🍽️ 카테고리", "${recipe['food_category']} | ${recipe['cooking_category']}"),
                const SizedBox(height: 14),
                _section("📌 재료", ""),
                ...ingredients.map((item) => _ingredientRow(item)),
                const SizedBox(height: 14),
                _section("💡 팁", recipe['tips'] ?? ''),
                const SizedBox(height: 14),
                _section("👩‍🍳 조리 순서", ""),
                ...methods.entries.map((e) => _methodItem(e.key, e.value)),
                const SizedBox(height: 14),
                _section("📊 영양 정보 (${nutrition['quantity']})", ""),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _nutriChip("칼로리", nutrition['calories'], "kcal"),
                    _nutriChip("단백질", nutrition['protein'], "g"),
                    _nutriChip("탄수화물", nutrition['carbohydrates'], "g"),
                    _nutriChip("지방", nutrition['fat'], "g"),
                    _nutriChip("나트륨", nutrition['sodium'], "mg"),
                  ],
                ),
                const SizedBox(height: 40),
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        if (content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
      ],
    );
  }

  Widget _ingredientRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 14))),
          Text(item['quantity'], style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _methodItem(String step, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Step $step", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(data['describe'], style: const TextStyle(fontSize: 14, height: 1.5)),
        if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(data['image_url'], fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _nutriChip(String label, dynamic value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_dining, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            "$label: $value$unit",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
