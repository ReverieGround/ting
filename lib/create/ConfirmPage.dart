import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../services/PostService.dart';
import '../../services/StorageService.dart';
import '../AppHeader.dart';
import '../models/PostInputData.dart';

class ConfirmPage extends StatefulWidget {
  final List<PostInputData> postInputs;
  const ConfirmPage({Key? key, required this.postInputs}) : super(key: key);

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  final _postService = PostService();
  final _storageService = StorageService();

  bool isUploading = false;
  final List<String> mealNames = const ['아침', '점심', '저녁'];
  final List<String> _visibilityValues = const ['PUBLIC', 'FOLLOWER', 'PRIVATE'];
  String visibility = 'PUBLIC';
  late String displayCapturedDate;

  static const double _kImageCardWidth = 250.0;
  static const double _kImageCardHeight = 200.0;
  static const double _kOverlapOffset = 50.0;

  @override
  void initState() {
    super.initState();
    displayCapturedDate = widget.postInputs.isNotEmpty
        ? widget.postInputs[0].capturedDate
        : DateFormat('yyyy. MM. dd HH:mm').format(DateTime.now());
  }

  Future<void> uploadAllPosts() async {
    if (!mounted) return;
    setState(() => isUploading = true);

    final failures = <String>[];

    try {
      bool allOk = true;

      for (int i = 0; i < widget.postInputs.length; i++) {
        final input = widget.postInputs[i];
        final meal = mealNames[i % mealNames.length];

        // 0) 입력 검사
        if (input.imageFiles.isEmpty) {
          // allOk = false;
          final msg = "[$i:$meal] 이미지가 비어 있음";
          failures.add(msg);
          debugPrint("[UploadPosts] $msg");
          continue;
        }
        if (input.content.trim().isEmpty) {
          allOk = false;
          final msg = "[$i:$meal] 내용이 비어 있음";
          failures.add(msg);
          debugPrint("[UploadPosts] $msg");
          continue;
        }

        // 1) 이미지 업로드
        List<String> urls = const [];
        try {
          urls = await _storageService.uploadPostImages(input.imageFiles);
          if (urls.isEmpty) {
            allOk = false;
            final msg = "[$i:$meal] 이미지 업로드 실패: 빈 URL 목록";
            failures.add(msg);
            debugPrint("[UploadPosts] $msg");
            continue;
          }
        } catch (e, st) {
          allOk = false;
          final msg = "[$i:$meal] 이미지 업로드 예외: $e";
          failures.add(msg);
          debugPrint("[UploadPosts] $msg\n$st");
          continue;
        }

        // 2) capturedAt 파싱
        DateTime? capturedAt;
        try {
          capturedAt = DateFormat('yyyy. MM. dd HH:mm').parse(input.capturedDate);
        } catch (e) {
          // 실패해도 진행 (서버타임으로 대체되니까)
          debugPrint("[UploadPosts] [$i:$meal] capturedDate 파싱 실패: ${input.capturedDate} ($e)");
        }

        // 3) Firestore create
        try {
          // visibility 값이 규칙 허용 값인지 사전 확인 (PUBLIC/FOLLOWER/PRIVATE)
          if (!(visibility == 'PUBLIC' || visibility == 'FOLLOWER' || visibility == 'PRIVATE')) {
            allOk = false;
            final msg = "[$i:$meal] visibility 값 불일치: $visibility";
            failures.add(msg);
            debugPrint("[UploadPosts] $msg");
            continue;
          }

          final postId = await _postService.createPost(
            title: "$meal 식사",
            content: input.content,
            imageUrls: urls,
            visibility: visibility,
            recipeId: input.recommendRecipe ? "some-recipe-id" : null,
            category: "${input.selectedCategory}",
            value: "${input.selectedValue}",
            region: null,
            capturedAt: capturedAt,
          );

          if (postId == null) {
            allOk = false;
            final msg = "[$i:$meal] createPost 결과 null";
            failures.add(msg);
            debugPrint("[UploadPosts] $msg");
          } else {
            debugPrint("[UploadPosts] [$i:$meal] 업로드 성공: postId=$postId");
          }
        } on FirebaseException catch (e, st) {
          allOk = false;
          final msg = "[$i:$meal] Firestore 예외: ${e.code} ${e.message}";
          failures.add(msg);
          debugPrint("[UploadPosts] $msg\n$st");
        } catch (e, st) {
          allOk = false;
          final msg = "[$i:$meal] 알 수 없는 예외: $e";
          failures.add(msg);
          debugPrint("[UploadPosts] $msg\n$st");
        }
      }

      if (!mounted) return;
      setState(() => isUploading = false);

      // UI 알림
      if (allOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 게시물 업로드 완료!')),
        );
        Navigator.pop(context, true);
      } else {
        // 실패 이유를 2~3줄로 요약해서 보여주기
        final brief = failures.take(3).join(' · ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일부 실패: $brief${failures.length > 3 ? " (+${failures.length - 3}건)" : ""}')),
        );
      }
    } finally {
      if (mounted && isUploading) {
        setState(() => isUploading = false);
      }
    }
  }

  String _labelOfVisibility(String v) {
    if (v == 'PUBLIC') return '전체 공개';
    if (v == 'FOLLOWER') return '내 친구만';
    return '비공개';
  }

  Widget _buildCardRackImages(List<File> images) {
    final totalStackWidth =
        images.isNotEmpty ? (images.length - 1) * _kOverlapOffset + _kImageCardWidth : _kImageCardWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: totalStackWidth,
        height: _kImageCardHeight,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: List.generate(images.length, (index) {
            final offset = index * _kOverlapOffset;
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
                  child: Image.file(images[index], fit: BoxFit.cover),
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
    final allImages = widget.postInputs.expand((e) => e.imageFiles).toList();

    return Scaffold(
      appBar: AppHeader(
        backgroundColor: Colors.white,
        centerTitle: true,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Color.fromRGBO(255, 110, 199, 1)),
            const SizedBox(width: 8),
            Text(
              DateFormat('yyyy. MM. dd').format(
                DateFormat('yyyy. MM. dd HH:mm').parse(displayCapturedDate),
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black, letterSpacing: -0.5),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: allImages.isEmpty
                ? const Center(child: Text('선택된 이미지가 없습니다.'))
                : _buildCardRackImages(allImages),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('공개 범위', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    items: _visibilityValues
                        .map((v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text(
                                _labelOfVisibility(v),
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                              ),
                            ))
                        .toList(),
                    value: visibility,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => visibility = v);
                    },
                    buttonStyleData: ButtonStyleData(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                      width: 150,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
                      offset: const Offset(0, -5),
                      scrollbarTheme: ScrollbarThemeData(
                        radius: const Radius.circular(40),
                        thickness: const MaterialStatePropertyAll(6),
                        thumbVisibility: const MaterialStatePropertyAll(true),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 40,
                      padding: EdgeInsets.only(left: 14, right: 14),
                    ),
                  ),
                ),
              ]),
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
              backgroundColor: const Color.fromRGBO(255, 110, 199, 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Color.fromRGBO(255, 110, 199, 1), width: 1),
              ),
            ),
            child: isUploading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '업로드하기',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
