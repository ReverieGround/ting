import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; 
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../services/auth_service.dart';
import '../../../config.dart';
import '../../../widgets/common/vibe_header.dart';
import '../../models/PostInputData.dart'; // Ensure PostInputData is correctly defined here

class FinalCheck extends StatefulWidget {
  final List<PostInputData> postInputs;
  const FinalCheck({Key? key, required this.postInputs}) : super(key: key);

  @override
  State<FinalCheck> createState() => _FinalCheckState();
}

class _FinalCheckState extends State<FinalCheck> {
  bool isUploading = false;
  final List<String> mealNames = ['아침', '점심', '저녁'];
  String visibility = 'PUBLIC';
  late String displayCapturedDate;
  
  // 카드 랙 개별 이미지 너비 및 높이 (필요에 따라 조절)
  static const double _kImageCardWidth = 250.0;
  static const double _kImageCardHeight = 200.0;

  // ✨ 카드 겹침 정도를 조절하는 상수 (이 값을 조절하여 겹침 정도를 변경하세요) ✨
  // 값이 작을수록 더 많이 겹치고, 클수록 덜 겹칩니다.
  static const double _kOverlapOffset = 50.0; // 40.0, 60.0 등으로 테스트해보세요.



  @override
  void initState() {
    super.initState();
    displayCapturedDate = widget.postInputs.isNotEmpty
        ? widget.postInputs[0].capturedDate
        : DateFormat('yyyy. MM. dd HH:mm').format(DateTime.now());
  }

  Future<void> uploadAllPosts() async {
    setState(() => isUploading = true);

    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) setState(() => isUploading = false);
      return;
    }

    bool allUploadedSuccessfully = true;

    for (int i = 0; i < widget.postInputs.length; i++) {
      final input = widget.postInputs[i];
      if (input.imageFiles.isEmpty || input.content.trim().isEmpty) {
        allUploadedSuccessfully = false; // Mark if any post is skipped
        continue;
      }

      List<String> uploadedImageUrls = [];
      for (final imageFile in input.imageFiles) {
        final imageUrl = await _uploadImageToFirebase(imageFile);
        if (imageUrl != null) {
          uploadedImageUrls.add(imageUrl);
        } else {
          allUploadedSuccessfully = false; // Mark if any image fails to upload
        }
      }

      if (uploadedImageUrls.isEmpty) {
        allUploadedSuccessfully = false; // Mark if no images were uploaded for this post
        continue;
      }

      final payload = {
        "title": "${mealNames[i]} 식사",
        "content": input.content,
        "image_urls": uploadedImageUrls,
        "visibility": "PUBLIC", // This seems to be hardcoded, consider making it dynamic from input.selectedValue
        "recipe_id": input.recommendRecipe ? "some-recipe-id" : null,
        "category": "${input.selectedCategory}",
        "value": "${input.selectedValue}",
      };

      try {
        final res = await http.post(
          Uri.parse('${Config.baseUrl}/post/upload'),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(payload),
        );

        if (res.statusCode != 200) {
          allUploadedSuccessfully = false;
          debugPrint("[$i] Post upload failed: ${res.statusCode}, Response: ${res.body}");
        }
      } catch (e) {
        allUploadedSuccessfully = false;
        debugPrint("[$i] Post upload network error: $e");
      }
    }

    if (mounted) {
      setState(() => isUploading = false);
      if (allUploadedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 게시물 업로드 완료!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일부 게시물 업로드 실패 또는 건너뜀.')),
        );
      }
    }
  }

  Future<String?> _uploadImageToFirebase(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName = 'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.${file.path.split('.').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Firebase 이미지 업로드 실패: $e");
      return null;
    }
  }


  
  Widget _buildCardRackImages(List<File> images) {
    // 스택의 총 너비 계산: (이미지 개수 - 1) * 겹침 정도 + 마지막 이미지 너비
    // 이미지가 하나도 없거나 하나일 경우를 처리 (하나일 경우 겹침이 없음)
    double totalStackWidth = (images.length > 0)
        ? (images.length - 1) * _kOverlapOffset + _kImageCardWidth
        : 0.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 패딩 추가
      child: SizedBox(
        // 스택 내용물의 실제 너비를 지정. 이미지가 없으면 0, 하나만 있으면 이미지 너비.
        width: totalStackWidth > 0 ? totalStackWidth : _kImageCardWidth,
        height: _kImageCardHeight,
        child: Stack(
          alignment: Alignment.centerLeft, // 이미지들이 왼쪽에서부터 쌓이도록 정렬
          children: List.generate(images.length, (index) {
            double offset = index * _kOverlapOffset; // 각 이미지의 왼쪽 위치 오프셋
            return Positioned(
              left: offset,
              child: Container(
                width: _kImageCardWidth,
                height: _kImageCardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final List<File> allImages = widget.postInputs.expand((input) => input.imageFiles).toList();

    return Scaffold(
      appBar: VibeHeader(
        backgroundColor: Colors.white,
        centerTitle: true,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color.fromRGBO(255, 110, 199, 1),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('yyyy. MM. dd').format(
                DateFormat('yyyy. MM. dd HH:mm').parse(displayCapturedDate),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            child: allImages.isEmpty
                ? const Center(child: Text('선택된 이미지가 없습니다.'))
                : _buildCardRackImages(allImages),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '공개 범위',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // --- Replaced GestureDetector with DropdownButton2 ---
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true, // Takes available width
                      hint: const Text(
                        '선택하세요',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      items: ['PUBLIC', 'FRIENDS_ONLY']
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item == 'PUBLIC' ? '전체 공개' : '내 친구만', // Display localized text
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black, // Text color for options
                                  ),
                                ),
                              ))
                          .toList(),
                      value: visibility, // Bind to PostInputData.selectedValue
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            visibility = newValue;
                          });
                        }
                      },
                      buttonStyleData: ButtonStyleData(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          // border: Border.all(color: Colors.grey.shade300), // Subtle border
                          color: Colors.white, // Background color of the button
                        ),
                      ),
                      iconStyleData: const IconStyleData(
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded, // Dropdown arrow icon
                          color: Colors.grey,
                        ),
                        iconSize: 24,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        width: 150, // Adjust width if needed
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        offset: const Offset(0, -5), // Adjust dropdown position
                        scrollbarTheme: ScrollbarThemeData(
                          radius: const Radius.circular(40),
                          thickness: MaterialStateProperty.all(6),
                          thumbVisibility: MaterialStateProperty.all(true),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                        padding: EdgeInsets.only(left: 14, right: 14),
                      ),
                    ),
                  ),
                ],
              
              )
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isUploading ? null : uploadAllPosts,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(255, 110, 199, 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(
                  color: Color.fromRGBO(255, 110, 199, 1),
                  width: 1,
                ),
              ),
            ),
            child: isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '업로드하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}