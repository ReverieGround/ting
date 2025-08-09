import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/common/vibe_toggle_box.dart';
import 'recipe_form_provider.dart';

class RecipeTypeSelector extends StatelessWidget {
  const RecipeTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isOriginal = context.watch<RecipeFormProvider>().isOriginal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: VibeToggleBox(
              selected: isOriginal,
              text: "직접 창작한 오리지널 레시피예요",
              onTap: () => context.read<RecipeFormProvider>().setIsOriginal(true),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            child: VibeToggleBox(
              selected: !isOriginal,
              text: "다른 레시피를 보고 응용했어요",
              onTap: () => context.read<RecipeFormProvider>().setIsOriginal(false),
            ),
          ),
        
          
        ],
      ),
    );
  }
}
