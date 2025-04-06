import 'dart:io';

import 'package:flutter/material.dart';

class InstructionStep {
  final String text;
  final File? image;

  InstructionStep({required this.text, this.image});

  Map<String, dynamic> toJson() => {
        'text': text,
        'image_path': image?.path, // 또는 업로드 후 URL로 대체
      };
}

class Ingredient {
  final String name;
  final String amount;

  Ingredient({required this.name, required this.amount});

  Map<String, String> toJson() => {
        'name': name,
        'amount': amount,
      };
}

class RecipeFormProvider with ChangeNotifier {
  String title = '';
  String description = '';
  File? image;

  List<Ingredient> ingredients = [];
  List<InstructionStep> instructions = [];

  String? parentRecipeId;
  List<String> tags = [];
  bool isOriginal = true;

  // 추가할 필드
  Set<String> appliedChangeTags = {};
  Map<String, String> changeDescriptions = {};

  // 메서드
  void toggleChangeTag(String tag) {
    if (appliedChangeTags.contains(tag)) {
      appliedChangeTags.remove(tag);
      changeDescriptions.remove(tag);
    } else {
      appliedChangeTags.add(tag);
      changeDescriptions[tag] = "";
    }
    notifyListeners();
  }

  void setChangeDescription(String tag, String desc) {
    changeDescriptions[tag] = desc;
    notifyListeners();
  }


  void setIsOriginal(bool value) {
    isOriginal = value;
    notifyListeners();
  }

  // Setters
  void setTitle(String value) {
    title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  void setImage(File file) {
    image = file;
    notifyListeners();
  }

  void addIngredient(Ingredient ing) {
    ingredients.add(ing);
    notifyListeners();
  }

  void removeIngredientAt(int index) {
    ingredients.removeAt(index);
    notifyListeners();
  }

  void addInstruction(InstructionStep step) {
    instructions.add(step);
    notifyListeners();
  }

  void removeInstructionAt(int index) {
    instructions.removeAt(index);
    notifyListeners();
  }

  void setParentRecipeId(String? id) {
    parentRecipeId = id;
    notifyListeners();
  }

  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    tags.remove(tag);
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'instructions': instructions.map((e) => e.toJson()).toList(),
        'parent_id': parentRecipeId,
        'tags': tags,
        // image: 업로드 후 image_url로 대체 예정
      };
}
