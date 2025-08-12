import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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

    try {
      bool allOk = true;

      for (int i = 0; i < widget.postInputs.length; i++) {
        final input = widget.postInputs[i];
        if (input.imageFiles.isEmpty || input.content.trim().isEmpty) {
          allOk = false;
          continue;
        }

        final urls = await _storageService.uploadPostImages(input.imageFiles);
        if (urls.isEmpty) {
          allOk = false;
          continue;
        }

        final titlePrefix = mealNames[i % mealNames.length];

        DateTime? capturedAt;
        try {
          capturedAt = DateFormat('yyyy. MM. dd HH:mm').parse(input.capturedDate);
        } catch (_) {}

        final postId = await _postService.createPost(
          title: "$titlePrefix 식사",
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
        }
      }

      if (!mounted) return;
      setState(() => isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(allOk ? '모든 게시물 업로드 완료!' : '일부 게시물 업로드 실패 또는 건너뜀.')),
      );
      if (allOk) Navigator.pop(context, true);
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
