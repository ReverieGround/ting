import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/common/vibe_text_field.dart';
import '../widgets/common/vibe_check_chip.dart';
import 'recipe_form_provider.dart';

class IngredientListSection extends StatefulWidget {
  const IngredientListSection({super.key});

  @override
  State<IngredientListSection> createState() => _IngredientListSectionState();
}

class _IngredientListSectionState extends State<IngredientListSection> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  void _addIngredient() {
    final name = _nameController.text.trim();
    final amount = _amountController.text.trim();
    if (name.isEmpty || amount.isEmpty) return;

    context.read<RecipeFormProvider>().addIngredient(
      Ingredient(name: name, amount: amount),
    );

    _nameController.clear();
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = context.watch<RecipeFormProvider>().ingredients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("재료", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: VibeTextField(controller: _nameController, hint: "재료명"),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VibeTextField(controller: _amountController, hint: "양 (예: 1개)"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addIngredient, child: const Text("+")),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < ingredients.length; i++)
              VibeCheckChip(
                label: "${ingredients[i].name} - ${ingredients[i].amount}",
                onDeleted: () => context.read<RecipeFormProvider>().removeIngredientAt(i),
              ),
          ],
        )
      ],
    );
  }
}
