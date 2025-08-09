import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../widgets/common/vibe_text_field.dart';
import 'recipe_form_provider.dart';

class RecipeTitleSection extends StatefulWidget {
  const RecipeTitleSection({super.key});

  @override
  State<RecipeTitleSection> createState() => _RecipeTitleSectionState();
}

class _RecipeTitleSectionState extends State<RecipeTitleSection> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _imageFile;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      context.read<RecipeFormProvider>().setImage(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.read<RecipeFormProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("레시피 제목", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        VibeTextField(
          controller: _titleController,
          hint: "예: 백종원 김치찌개",
        ),
        const SizedBox(height: 16),

        const Text("간단한 설명", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        VibeTextField(
          controller: _descController,
          hint: "예: 진하고 구수한 맛의 김치찌개 레시피입니다.",
        ),
        const SizedBox(height: 16),

        const Text("대표 이미지", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
          ),
        ),
      ],
    );
  }
}
