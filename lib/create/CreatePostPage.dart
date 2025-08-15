// CreatePostPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../AppHeader.dart';
import '../models/PostInputData.dart';
import 'ConfirmPage.dart';

import 'helpers/ImagePickerFlow.dart';
import 'helpers/ExifHelper.dart';

import 'widgets/DateTimePickerDialog.dart';
import 'widgets/HeaderDateTitle.dart';
import 'widgets/ImageCarousel.dart';
import 'widgets/ChipsCategory.dart';
import 'widgets/ChipsReview.dart';
import 'widgets/PostTextField.dart';
import 'widgets/RecommendRecipeToggle.dart';
import 'widgets/SectionMealKit.dart';
import 'widgets/SectionRestaurant.dart';
import 'widgets/SectionDelivery.dart';
import 'widgets/BottomNextButton.dart';
import 'dart:io';

// ========= 유효성/하이라이트 =========
class _FieldErrors {
  bool image = false;
  bool category = false;
  bool review = false;
  bool text = false;
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final PageController _pageController = PageController(viewportFraction: 0.75);

  /// 이미지 1장 = PostInputData 1개
  final List<PostInputData> postInputs = [];

  final List<String> categories = ['요리', '밀키트', '식당', '배달'];
  final List<Map<String, String>> reviewValues = [
    {'label': 'Fire', 'image': 'assets/fire.png'},
    {'label': 'Tasty', 'image': 'assets/tasty.png'},
    {'label': 'Soso', 'image': 'assets/soso.png'},
    {'label': 'Woops', 'image': 'assets/woops.png'},
    {'label': 'Wack', 'image': 'assets/wack.png'},
  ];

  int _currentIndex = 0;
  bool isUploading = false;
  String capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(DateTime.now());
  DateTime selectedDate = DateTime.now();

  final Map<int, _FieldErrors> _errors = {};
  _FieldErrors _errFor(int i) => _errors[i] ?? _FieldErrors();

  bool _validateAllAndHighlight() {
    bool ok = true;
    for (int i = 0; i < postInputs.length; i++) {
      final input = postInputs[i];
      final e = _FieldErrors()
        ..image = input.imageFiles.isEmpty
        ..category = input.selectedCategory.trim().isEmpty
        ..review = input.selectedValue.trim().isEmpty
        ..text = input.textController.text.trim().isEmpty;
      _errors[i] = e;
      if (e.image || e.category || e.review || e.text) ok = false;
    }
    setState(() {}); // 하이라이트 반영
    return ok;
  }

  @override
  void initState() {
    super.initState();
    // 첫 진입 시 멀티 선택 흐름 실행 (원하면 버튼으로 트리거해도 됨)
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImagesInitial());
  }

  @override
  void dispose() {
    for (var input in postInputs) {
      input.textController.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openDateTimePicker() async {
    final picked = await showCustomDateTimeDialog(
      context: context,
      initial: selectedDate,
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(picked);
      });
    }
    // picked == null (취소) 이면 아무 것도 안 함 → 다이얼로그만 닫힘
  }

  /// 앱 진입 후 최초 멀티 이미지 선택 → 이미지 수만큼 페이지 생성
  Future<void> _pickImagesInitial() async {
    final flow = ImagePickerFlow();
    final result = await flow.pickAndEdit(context); // 멀티 선택/편집
    if (result == null || result.files.isEmpty) return;

    setState(() {
      postInputs
        ..clear()
        ..addAll(result.files.map((f) => PostInputData(imageFiles: [f])));
      _currentIndex = 0;
      if (result.takenAt != null) {
        selectedDate = result.takenAt!;
        capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(result.takenAt!);
      }
    });
  }

  /// 해당 페이지 이미지 교체
  Future<void> _replaceImageAt(int index) async {
    final flow = ImagePickerFlow();
    final result = await flow.pickAndEdit(context);
    if (result == null || result.files.isEmpty) return;

    setState(() {
      postInputs[index].imageFiles = [result.files.first]; // 단 1장만
      if (result.takenAt != null) {
        selectedDate = result.takenAt!;
        capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(result.takenAt!);
      }
    });
  }

  /// 이미지 더 추가 (선택 사항: AppBar 버튼 등에서 호출)
  Future<void> _addMoreImages() async {
    final flow = ImagePickerFlow();
    final result = await flow.pickAndEdit(context);
    if (result == null || result.files.isEmpty) return;

    setState(() {
      for (final f in result.files) {
        postInputs.add(PostInputData(imageFiles: [f]));
      }
      _currentIndex = postInputs.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final hasPages = postInputs.isNotEmpty;
    final currentInput = hasPages ? postInputs[_currentIndex] : null;
    final err = hasPages ? _errFor(_currentIndex) : _FieldErrors();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppHeader(
        backgroundColor: Colors.white,
        centerTitle: true,
        titleWidget: HeaderDateTitle(
          capturedDate: capturedDate,
          onTap: _openDateTimePicker,
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // ========= 이미지(페이지) =========
            SizedBox(
              height: 220,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasPages && err.image ? Colors.red : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasPages
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: postInputs.length,
                        onPageChanged: (i) => setState(() => _currentIndex = i),
                        itemBuilder: (_, index) {
                          final input = postInputs[index];
                          final file = input.imageFiles.isNotEmpty ? input.imageFiles.first : null;

                          // ImageCarousel 유지(확장 대비). 지금은 1장만 담아 전달.
                          return GestureDetector(
                            onTap: () => _replaceImageAt(index),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ImageCarousel(
                                    pageController: _pageController,
                                    images: file != null ? <File>[file] : <File>[],
                                    onTap: () => _replaceImageAt(index),
                                  ),
                                ),
                                // 페이지 삭제 버튼
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        postInputs.removeAt(index);
                                        if (_currentIndex >= postInputs.length) {
                                          _currentIndex = (postInputs.length - 1).clamp(0, 1 << 20);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: TextButton.icon(
                          onPressed: _pickImagesInitial,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('이미지 선택'),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ========= 입력 섹션들 =========
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: hasPages
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 카테고리
                          CategoryChips(
                            categories: categories,
                            selected: currentInput!.selectedCategory,
                            onSelect: (v) => setState(() {
                              currentInput.selectedCategory =
                                  currentInput.selectedCategory == v ? "" : v;
                              _errors[_currentIndex]?.category = false;
                            }),
                            showBorder: err.category,          // ⬅️ 에러일 때만 빨간 테두리
                            borderColor: Colors.red,
                            borderWidth: 1.5,
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                          ),
                          const SizedBox(height: 8),

                          // 리뷰
                          ReviewChips(
                            items: reviewValues,
                            selected: currentInput.selectedValue,
                            onSelect: (v) => setState(() {
                              currentInput.selectedValue =
                                currentInput.selectedValue == v ? "" : v;
                              _errors[_currentIndex]?.review = false;
                            }),
                            showBorder: err.review, // 에러일 때만 빨간 테두리
                          ),
                          const SizedBox(height: 16),

                          // 내용
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: err.text  ? Colors.red : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PostTextField(
                              controller: currentInput.textController,
                              onChanged: (value) {
                                if (value.trim().isNotEmpty && err.text) {
                                  setState(() {
                                    err.text = false;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            if (hasPages && currentInput!.selectedCategory.contains('요리'))
              RecommendRecipeToggle(
                value: currentInput.recommendRecipe,
                onChanged: (v) => setState(() => currentInput.recommendRecipe = v),
              ),
            if (hasPages && currentInput!.selectedCategory.contains('밀키트'))
              SectionMealKit(
                value: currentInput.mealKitLink,
                onSubmitted: (v) => setState(() => currentInput.mealKitLink = v),
              ),
            if (hasPages && currentInput!.selectedCategory.contains('식당'))
              SectionRestaurant(
                value: currentInput.restaurantLink,
                onSubmitted: (v) => setState(() => currentInput.restaurantLink = v),
              ),
            if (hasPages && currentInput!.selectedCategory.contains('배달'))
              SectionDelivery(
                value: currentInput.deliveryLink,
                onSubmitted: (v) => setState(() => currentInput.deliveryLink = v),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboard),
        child: SafeArea(
          top: false,
          child: BottomNextButton(
            isLoading: isUploading,
            onPressed: () {
              FocusScope.of(context).unfocus();

              if (postInputs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이미지를 먼저 선택해 주세요.')),
                );
                return;
              }

              final ok = _validateAllAndHighlight();
              if (!ok) {
                // 첫 누락 페이지로 이동
                final firstBad = List.generate(postInputs.length, (i) => i).firstWhere(
                  (i) {
                    final e = _errFor(i);
                    return e.image || e.category || e.review || e.text;
                  },
                  orElse: () => 0,
                );
                _pageController.animateToPage(
                  firstBad,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );

                final missingFields = <String>[];

                if (currentInput!.imageFiles.isEmpty) missingFields.add("이미지");
                if (currentInput.selectedCategory.isEmpty) missingFields.add("카테고리");
                if (currentInput.selectedValue.isEmpty) missingFields.add("만족도");
                if (currentInput.textController.text.trim().isEmpty) missingFields.add("리뷰내용");

                String message;
                if (missingFields.isEmpty) {
                  message = "";
                } else if (missingFields.length <= 2) {
                  message = "${missingFields.join(', ')} 항목을 채워주세요.";
                } else {
                  final firstTwo = missingFields.take(2).join(', ');
                  message = "$firstTwo 등 항목을 채워주세요.";
                }

                if (message.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      duration: const Duration(milliseconds: 500), // 표시 시간 2초로 변경
                    ),
                  );
                }
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ConfirmPage(postInputs: postInputs)),
              );
            },
          ),
        ),
      ),
    );
  }
}
