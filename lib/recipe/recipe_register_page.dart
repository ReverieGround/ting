import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'recipe_type_selector.dart';
import 'parent_recipe_link_section.dart';
import 'recipe_change_options_section.dart';
import 'submit_button.dart';
import '../AppHeader.dart'; 
import 'recipe_form_provider.dart';

class RecipeRegisterPage extends StatelessWidget {
  const RecipeRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isOriginal = context.watch<RecipeFormProvider>().isOriginal;

    return Scaffold(
      appBar: AppHeader(
        titleWidget: Text(
          "레시피 등록",
          style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
      )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RecipeTypeSelector(),
            const ParentRecipeLinkSection(),  // 조건부 렌더링 🎯
            const RecipeChangeOptionsSection(),
            // const SubmitButton(),
          ],
        ),
      ),

    bottomNavigationBar: const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SubmitButton(),
    ),
    );
  }
}
