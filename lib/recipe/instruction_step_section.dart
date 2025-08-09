import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../widgets/common/vibe_text_field.dart';
import 'recipe_form_provider.dart';

class InstructionStepSection extends StatefulWidget {
  const InstructionStepSection({super.key});

  @override
  State<InstructionStepSection> createState() => _InstructionStepSectionState();
}

class _InstructionStepSectionState extends State<InstructionStepSection> {
  final List<TextEditingController> _controllers = [];

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final text = _controllers[index].text;
      context.read<RecipeFormProvider>().instructions[index] =
          InstructionStep(text: text, image: file);
      setState(() {});
    }
  }

  void _addStep() {
    setState(() {
      _controllers.add(TextEditingController());
    });
    context.read<RecipeFormProvider>().addInstruction(
      InstructionStep(text: "", image: null),
    );
  }

  void _removeStep(int index) {
    setState(() {
      _controllers.removeAt(index);
    });
    context.read<RecipeFormProvider>().removeInstructionAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<RecipeFormProvider>().instructions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("조리 순서", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("단계 ${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                VibeTextField(
                  controller: _controllers[i],
                  hint: "이 단계에서 해야 할 설명을 입력해주세요",
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _pickImage(i),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: steps[i].image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(steps[i].image!, fit: BoxFit.cover),
                          )
                        : const Center(child: Icon(Icons.image, color: Colors.grey, size: 40)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeStep(i),
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: _addStep,
          icon: const Icon(Icons.add),
          label: const Text("단계 추가"),
        ),
      ],
    );
  }
}
