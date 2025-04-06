import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'recipe_form_provider.dart';
import '../../../config.dart'; // baseUrl 정의된 곳

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});

  Future<String?> _uploadImage(File imageFile) async {
    final uri = Uri.parse("${Config.baseUrl}/post/upload_image");
    final request = http.MultipartRequest("POST", uri)
      ..files.add(await http.MultipartFile.fromPath("image", imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      final data = json.decode(res);
      return data['url']; // 서버 응답 포맷에 따라 수정
    } else {
      debugPrint("이미지 업로드 실패: ${response.statusCode}");
      return null;
    }
  }

  Future<void> _submitRecipe(BuildContext context) async {
    final provider = context.read<RecipeFormProvider>();

    // 이미지 업로드
    String? imageUrl;
    if (provider.image != null) {
      imageUrl = await _uploadImage(provider.image!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이미지 업로드에 실패했습니다.")),
        );
        return;
      }
    }

    // 최종 JSON
    final recipeData = provider.toJson();
    recipeData['image_url'] = imageUrl;

    // 레시피 등록 API 호출
    final res = await http.post(
      Uri.parse("${Config.baseUrl}/recipe/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(recipeData),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("레시피가 등록되었습니다!")),
      );
      Navigator.pop(context); // 성공 시 뒤로 가기
    } else {
      debugPrint("레시피 등록 실패: ${res.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("레시피 등록에 실패했습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 62, 62, 62),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ElevatedButton.icon(
        label: const Text("작성하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        onPressed: () => _submitRecipe(context),
      ),
    );
  }
}
