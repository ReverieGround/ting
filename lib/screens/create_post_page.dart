import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../widgets/common/vibe_header.dart'; 
import '../services/auth_service.dart';
import '../config.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  int _currentIndex = 0;

  final List<String> mealNames = ['아침', '점심', '저녁'];
  final List<String> categories = ['요리', '밀키트', '식당', '배달'];
  final List<String> emojis = ['🔥 Fire', '😋 Tasty', '🤔 So-so', '😑 Womp'];

  final List<_PostInputData> postInputs = List.generate(3, (_) => _PostInputData());
  final ImagePicker _picker = ImagePicker();

  DateTime selectedDate = DateTime.now();

  String get formattedDate => DateFormat('yyyy. MM. dd').format(selectedDate);

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ko'), // 한글 달력
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }
  
  Future<void> pickImage(int index) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => postInputs[index].imageFile = File(picked.path));
    }
  }

  Future<void> uploadAllPosts() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    for (int i = 0; i < 3; i++) {
      final input = postInputs[i];
      if (input.imageFile == null || input.content.trim().isEmpty) continue;

      final payload = {
        "title": "${mealNames[i]} 식사",
        "content": input.content,
        "image_urls": jsonEncode(["https://via.placeholder.com/300"]), // TODO: 이미지 업로드 후 URL
        "visibility": "PUBLIC",
        "recipe_id": input.recommendRecipe ? "some-recipe-id" : null,
      };

      final res = await http.post(
        Uri.parse('${Config.baseUrl}/post/upload'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      print("[$i] 업로드 상태: ${res.statusCode}, 응답: ${res.body}");
    }
  }
  Future<void> pickCustomDate(BuildContext context) async {
    DateTime tempPicked = selectedDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (innerContext) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.black,      // ✅ 선택된 날짜 배경색
                      onPrimary: Colors.white,    // ✅ 선택된 날짜 텍스트
                      surface: Colors.white,      // ✅ 달력 전체 배경
                      onSurface: Colors.black87,  // ✅ 기본 텍스트
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black, // 확인/취소 버튼 색
                      ),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    onDateChanged: (newDate) {
                      tempPicked = newDate;
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (tempPicked != selectedDate) {
      setState(() => selectedDate = tempPicked);
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentInput = postInputs[_currentIndex];

    return Scaffold(
      appBar: VibeHeader(
        titleWidget: const Text(
          "Yum Diary", 
          style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        )
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => pickCustomDate(context),
            child: Text(
              formattedDate,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // ✅ 이미지 슬라이더만 PageView로
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 3,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final input = postInputs[index];

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = (_pageController.page! - index).abs();
                      value = (1 - (value * 0.2)).clamp(0.8, 1.0); // 0.8~1.0 사이 scale
                    }

                    return Center(
                      child: Transform.scale(
                        scale: value,
                        child: GestureDetector(
                          onTap: () => pickImage(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                              image: input.imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(input.imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: input.imageFile == null
                                ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.white))
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),


          const SizedBox(height: 16),

          // ✅ 하단 입력 UI (항상 고정, 상태만 바뀜)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text("${mealNames[_currentIndex]} 입력", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // const SizedBox(height: 12),

                  // 카테고리
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = currentInput.selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            currentInput.selectedCategory = isSelected ? null : cat;
                          });
                        },
                        selectedColor: Colors.grey.shade600,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // ✅ 원하는 값
                        ),
                        showCheckmark: false,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 이모지 선택
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: emojis.map((e) {
                      final isSelected = currentInput.selectedEmoji == e;
                      return ChoiceChip(
                        label: Text(e),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => currentInput.selectedEmoji = e);
                        },
                        selectedColor: Colors.grey.shade600,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // ✅ 원하는 값
                        ),
                        showCheckmark: false,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 텍스트 입력
                  TextField(
                    controller: currentInput.textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '내용을 입력하세요',
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: currentInput.recommendRecipe,
                        onChanged: (val) => setState(() => currentInput.recommendRecipe = val ?? false),
                      ),
                      const Text("이 레시피 추천하기"),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ✅ 업로드 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: uploadAllPosts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('업로드하기', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostInputData {
  File? imageFile;
  String? selectedCategory;
  String? selectedEmoji;
  bool recommendRecipe = false;
  TextEditingController textController = TextEditingController();

  String get content => textController.text;
}
