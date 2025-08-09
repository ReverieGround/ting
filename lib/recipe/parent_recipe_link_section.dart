import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/common/vibe_text_field.dart';
import 'recipe_form_provider.dart';

class ParentRecipeLinkSection extends StatefulWidget {
  const ParentRecipeLinkSection({super.key});

  @override
  State<ParentRecipeLinkSection> createState() => _ParentRecipeLinkSectionState();
}

class _ParentRecipeLinkSectionState extends State<ParentRecipeLinkSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    context.read<RecipeFormProvider>().setParentRecipeId(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("오리지널 레시피 링크", style: TextStyle(fontSize: 16, color:Colors.black, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              VibeTextField(
                controller: _controller,
                hint: "링크를 첨부해 보세요",
                onTap: () {}, // 나중에 붙여넣기 등 UX 확장 가능
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.link, size: 20, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
