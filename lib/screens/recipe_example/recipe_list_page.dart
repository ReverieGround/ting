import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_page.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  List<Map<String, dynamic>> recipes = [];
  String chatInput = '';
  String? chatResponse;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final String jsonString = await rootBundle.loadString('assets/recipe_dict_filtered.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    setState(() {
      recipes = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> sendChatToServer(String message) async {
    setState(() {
      isLoading = true;
      chatResponse = null;
    });

    // 여기서는 서버와 통신하는 코드 → 이후 서버 구축 시 연결
    await Future.delayed(const Duration(seconds: 1)); // 임시 응답 대기

    setState(() {
      isLoading = false;
      chatResponse = '👉 "${message}"에 대해 추천되는 요리를 불러왔어요!'; // 추후 서버 응답으로 교체
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('레시피 추천')),
      body: Column(
        children: [
          if (chatResponse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Text(chatResponse!, style: const TextStyle(fontSize: 14)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return _buildRecipeCard(recipe);
              },
            ),
          ),
          _buildChatBar(),
        ],
      ),
    );
  }

  Widget _buildChatBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => chatInput = value,
                onSubmitted: (_) => _onSubmitChat(),
                decoration: InputDecoration(
                  hintText: '예: 두부랑 김치 있는데 뭐 해먹지?',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _onSubmitChat,
              icon: isLoading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.send, color: Colors.deepOrange),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmitChat() {
    if (chatInput.trim().isEmpty) return;
    sendChatToServer(chatInput.trim());
    chatInput = '';
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipePage(recipe: recipe)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  recipe['images']['original_url'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("${recipe['food_category']} · ${recipe['cooking_category']}",
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      recipe['tips'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
