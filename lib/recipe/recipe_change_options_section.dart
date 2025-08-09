import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/common/vibe_selectable_chip.dart';
import 'recipe_form_provider.dart';

class RecipeChangeOptionsSection extends StatelessWidget {
  const RecipeChangeOptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeFormProvider>();
    final selected = provider.appliedChangeTags;
    final changeDescriptions = provider.changeDescriptions;

    final options = [
      '재료 변경',
      '재료 추가',
      '계량 변경',
      '조리 기기 변경',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("내가 응용한 내용", style: TextStyle(fontWeight: FontWeight.w500, fontSize:16, color: Colors.black)),
          const SizedBox(height: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VibeSelectableChip(
                    label: option,
                    selected: isSelected,
                    onTap: () => context.read<RecipeFormProvider>().toggleChangeTag(option),
                  ),
                  const SizedBox(height: 8),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 120),
                        child: IntrinsicHeight(
                          child: TextField(
                            onChanged: (value) =>
                                context.read<RecipeFormProvider>().setChangeDescription(option, value),
                            controller: TextEditingController.fromValue(
                              TextEditingValue(
                                text: changeDescriptions[option] ?? '',
                                selection: TextSelection.collapsed(
                                  offset: (changeDescriptions[option] ?? '').length,
                                ),
                              ),
                            ),
                            decoration: InputDecoration(
                              hintText: "$option에 대해 공유해 보세요",
                              hintStyle: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 155, 155, 155)),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 245, 245, 245),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              isDense: false,
                            ),
                            textAlignVertical: TextAlignVertical.top,
                            maxLines: null,
                            expands: true, // 🎯 핵심! 텍스트필드를 부모에 꽉 차게 만듦
                          ),
                        ),
                      ),
                    )

                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
