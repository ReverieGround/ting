import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exif/exif.dart';
import 'package:uuid/uuid.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../services/AuthService.dart';
import '../../config.dart';
import '../AppHeader.dart';
import '../models/PostInputData.dart';
import 'widgets/FinalCheck.dart';
import 'EditPage.dart'; // EditPage 임포트

class CreatePostPage extends StatefulWidget {
  // final Function? headerCallback;
  const CreatePostPage({
    super.key,
    // this.headerCallback
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  String capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(DateTime.now());
  int _currentIndex = 0;
  bool isUploading = false;
  // final List<String> mealNames = ['아침', '점심', '저녁'];
  final List<String> categories = ['요리', '밀키트', '식당', '배달'];
  final List<Map<String, String>> reviewValues = [
    {'label': 'Fire', 'image': 'assets/fire.png'},
    {'label': 'Tasty', 'image': 'assets/tasty.png'},
    {'label': 'Soso', 'image': 'assets/soso.png'},
    {'label': 'Woops', 'image': 'assets/woops.png'},
    {'label': 'Wack', 'image': 'assets/wack.png'},
  ];
  
  // PostInputData 모델의 imageFile을 imageFiles (List<File>)로 변경했으므로,
  // List.generate 시에도 imageFiles 리스트를 초기화해줍니다.
  final List<PostInputData> postInputs = List.generate(3, (_) => PostInputData(imageFiles: []));
  final ImagePicker _picker = ImagePicker();

  DateTime selectedDate = DateTime.now();
  String get formattedDate => DateFormat('yyyy. MM. dd HH:mm').format(selectedDate);

  Future<void> pickCustomDateTime(BuildContext context, PostInputData currentInput) async {
    DateTime tempPicked = selectedDate;
    int hour = selectedDate.hour;
    int minute = selectedDate.minute;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (innerContext, setInnerState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.black,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black87,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: tempPicked,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now(),
                        onDateChanged: (newDate) {
                          setInnerState(() {
                            tempPicked = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              hour,
                              minute,
                            );
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        DropdownButton2<int>(
                          value: hour,
                          items: List.generate(24, (i) => DropdownMenuItem<int>(
                            value: i,
                            child: Text('$i시'),
                          )),
                          onChanged: (value) {
                            if (value != null) {
                              setInnerState(() {
                                hour = value;
                                tempPicked = DateTime(
                                  tempPicked.year,
                                  tempPicked.month,
                                  tempPicked.day,
                                  hour,
                                  minute,
                                );
                              });
                            }
                          },
                          buttonStyleData: const ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            height: 50,
                            width: 100,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200, // 최대 높이 (5~6개 아이템만 보이도록)
                            decoration: BoxDecoration(
                              color: Colors.grey[100], // 배경색
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        DropdownButton2<int>(
                          value: (minute ~/ 5) * 5,
                          items: List.generate(
                            12, // 0 ~ 55까지 5분 간격 (12개)
                            (i) => DropdownMenuItem<int>(
                              value: i * 5,
                              child: Text('${i * 5}분'),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setInnerState(() {
                                minute = value;
                                tempPicked = DateTime(
                                  tempPicked.year,
                                  tempPicked.month,
                                  tempPicked.day,
                                  hour,
                                  minute,
                                );
                              });
                            }
                          },
                          buttonStyleData: const ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            height: 50,
                            width: 100,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200, // 원하는 만큼 조절 가능 (예: 5~6개만 보이도록)
                            decoration: BoxDecoration(
                              color: Color(0xFFF0F0F0), // 배경색 지정
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context, // Use the BuildContext that can push to the main navigation stack
                              MaterialPageRoute(
                                builder: (context) => FinalCheck(postInputs: postInputs),
                              ),
                            );
                          },
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            )
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            if (tempPicked != selectedDate) {
                              setState(() => capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(tempPicked));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            '저장',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            )
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // pickImage 함수 수정: 여러 이미지 선택 및 EditPage 호출
  Future<void> pickImage(int index) async {
    final List<XFile> pickedImages = await _picker.pickMultiImage(); // 여러 이미지 선택
    if (pickedImages.isEmpty) {
      debugPrint('이미지 선택 취소');
      return;
    }

    // EditPage로 이동하여 이미지 편집 및 순서 변경
    final List<XFile>? editedFiles = await Navigator.push<List<XFile>?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPage(initialFiles: pickedImages), // 선택된 이미지들을 EditPage로 전달
      ),
    );

    if (editedFiles == null || editedFiles.isEmpty) {
      debugPrint('이미지 편집 취소 또는 편집된 이미지 없음');
      return;
    }

    // EditPage에서 반환된 XFile 리스트를 File 리스트로 변환
    List<File> finalImageFiles = [];
    for (var xFile in editedFiles) {
      finalImageFiles.add(File(xFile.path));
    }

    // 촬영 일자 추출 (첫 번째 이미지에서만 추출하도록 유지)
    if (finalImageFiles.isNotEmpty) {
      final DateTime? takenAt = await extractImageDate(finalImageFiles[0]);
      if (takenAt != null) {
        setState(() {
          capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(takenAt);
        });
      }
    }

    // 최종 편집된 이미지 파일들 저장
    setState(() {
      postInputs[index].imageFiles = finalImageFiles; // imageFile -> imageFiles로 변경
    });

    debugPrint('이미지 편집 완료 및 저장됨. 총 ${finalImageFiles.length}개 이미지.');
  }

  Future<DateTime?> extractImageDate(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        debugPrint("❗️ 파일 읽기 실패 또는 빈 파일");
        return null;
      }

      final tags = await readExifFromBytes(bytes);
      if (tags.containsKey('Image DateTime')) {
        final raw = tags['Image DateTime']!.printable; // ex: '2023:10:02 14:33:22'
        final parts = raw.split(' ');
        if (parts.length == 2) {
          final date = parts[0].replaceAll(':', '-');
          final time = parts[1];
          final parsed = DateTime.tryParse('$date $time');
          if (parsed != null) return parsed;
        }
        debugPrint("❗️ EXIF 포맷 오류: $raw");
      } else {
        debugPrint("ℹ️ EXIF에 촬영 일시 태그 없음");
      }
    } catch (e) {
      debugPrint("❌ EXIF 읽기 예외: $e");
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 모든 TextEditingController를 dispose
    for (var input in postInputs) {
      input.textController.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = postInputs[_currentIndex];

    return Scaffold(
      appBar: AppHeader(
        backgroundColor: Colors.white,
        centerTitle: true,
        titleWidget: InkWell(
          onTap: () => pickCustomDateTime(context, currentInput),
          child: Stack(
            alignment: Alignment.center, // Stack 내의 위젯들을 중앙 정렬
            children: [
              // 아이콘은 왼쪽에 배치
              Positioned(
                left: 0, // 또는 적절한 패딩 값
                child: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Color.fromRGBO(255, 110, 199, 1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  DateFormat('yyyy. MM. dd').format(
                    DateFormat('yyyy. MM. dd HH:mm').parse(capturedDate),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(child: Column(
        children: [
          SizedBox(
            height: 220,
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
                      value = (1 - (value * 0.2)).clamp(0.8, 1.0);
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: value,
                          child: GestureDetector(
                            onTap: () => pickImage(index), // 이미지 선택 및 편집 페이지로 이동
                            child: Container(
                              height: 220,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                // 여러 이미지를 표시하도록 변경
                                // image: input.imageFile != null
                                //     ? DecorationImage(
                                //         image: FileImage(input.imageFile!),
                                //         fit: BoxFit.cover,
                                //       )
                                //     : null,
                              ),
                              child: input.imageFiles.isEmpty // 이미지가 없으면 아이콘 표시
                                  ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.white))
                                  : ClipRRect( // 이미지가 있으면 가로 스크롤 가능한 리스트뷰로 표시
                                      borderRadius: BorderRadius.circular(16),
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: input.imageFiles.length,
                                        itemBuilder: (context, imgIndex) {
                                          return Image.file(
                                            input.imageFiles[imgIndex],
                                            width: 220, // PageView의 높이에 맞춰 너비도 설정
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ),
                        ),

                      ]
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final e = categories[index];
                        final isSelected = currentInput.selectedCategory == e;
                        return ChoiceChip(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          label: Text(e),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              currentInput.selectedCategory = isSelected ? "" : e;
                            });
                          },
                          selectedColor: const Color.fromRGBO(199, 244, 100, 1),
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.black : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide.none, 
                          ),
                          showCheckmark: false,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: reviewValues.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final String asset_value = "${reviewValues[index]['label']}";
                        final String asset_path = "${reviewValues[index]['image']}";
                        final isSelected = currentInput.selectedValue == asset_value;
                        return ChoiceChip(
                          label: Row( 
                            children: [
                              Image.asset(
                                asset_path, 
                                width: 15, 
                                height: 15,
                              ),
                              SizedBox(width: 4), 
                              Text(
                                asset_value, 
                                style: TextStyle(
                                  color: Colors.black,
                                )
                              ), 
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => currentInput.selectedValue = asset_value);
                          },
                          selectedColor: const Color.fromRGBO(199, 244, 100, 1),
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.black : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide.none, 
                          ),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          showCheckmark: false,
                          padding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 텍스트 입력
                  TextField(
                    controller: currentInput.textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '내용을 입력하세요',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),

            currentInput.selectedCategory.contains("요리") ?
            _buildRecommendRecipeWidget(currentInput) : const SizedBox.shrink(),

            currentInput.selectedCategory.contains("밀키트") ?
            _buildMealKitWidget(currentInput) : const SizedBox.shrink(),

            currentInput.selectedCategory.contains("식당") ?
            _buildRestaurantWidget(currentInput):const SizedBox.shrink(),

            currentInput.selectedCategory.contains("배달") ?
            _buildDeliverWidget(currentInput) : const SizedBox.shrink(),

        ],
      ),
      ),
      bottomNavigationBar: // ✅ 업로드 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinalCheck(postInputs: postInputs),
                  ),
                );},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // More rounded corners
                      side: const BorderSide(
                        color: Color.fromRGBO(255, 110, 199, 1), // Pink border color
                        width: 1, // Border thickness
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
                      '다음',
                      style: TextStyle(
                        color: Color.fromRGBO(255, 110, 199, 1), // Pink background color
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
            ),
          ),
    );
  }


  // Your "Recommend Recipe" widget for "요리"
  Widget _buildRecommendRecipeWidget(PostInputData inputData) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: 250,
        child: InkWell(
          borderRadius: BorderRadius.circular(16), // ✅ ripple 범위 설정
          onTap: () {
              setState(() => inputData.recommendRecipe = !inputData.recommendRecipe);
            },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade400, // ✅ border 제거 (또는 강조용 설정)
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up,
                  size: 14,
                  color: inputData.recommendRecipe ? Colors.amber : Colors.black54,
                ),
                const SizedBox(width: 4),
                const Text(
                  "이 레시피 추천",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealKitWidget(PostInputData inputData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity, 
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Row(
          children: [
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: inputData.mealKitLink), // Connect to data
                onSubmitted: (value) {
                  setState(() {
                    inputData.mealKitLink = value;
                  });
                  debugPrint('mealKit search submitted: ${inputData.mealKitLink}');
                  // 입력 완료 후 키보드 숨기기 (선택 사항)
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: '밀키트 구매 링크를 공유해 보세요',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none, // Remove default TextField border
                  isDense: true, // Reduce vertical space
                  contentPadding: EdgeInsets.zero, // Remove default content padding
                  fillColor: Colors.transparent,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10), // Spacing between text field and icon
            InkWell(
              onTap: (){},
              child: Image.asset(
                'assets/link.png', 
                width: 20, 
                height: 20,
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantWidget(PostInputData inputData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Row(
          children: [
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: inputData.restaurantLink), // Connect to data
                onSubmitted: (value) {
                  setState(() {
                    inputData.restaurantLink = value;
                  });
                  debugPrint('Restaurant search submitted: ${inputData.restaurantLink}');
                  // 입력 완료 후 키보드 숨기기 (선택 사항)
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: '식당명을 검색해 보세요',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none, // Remove default TextField border
                  isDense: true, // Reduce vertical space
                  contentPadding: EdgeInsets.zero, // Remove default content padding
                  fillColor: Colors.transparent,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10), // Spacing between text field and icon
            InkWell(
              onTap: (){},
              child: Image.asset(
                'assets/search.png', 
                width: 20, 
                height: 20,
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverWidget(PostInputData inputData) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity, // Take full width
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Row(
          children: [
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller:  TextEditingController(text: inputData.deliveryLink), // Connect to data
                onSubmitted: (value) {
                  setState(() {
                    inputData.deliveryLink = value;
                  });
                  debugPrint('delivery search submitted: ${inputData.deliveryLink}');
                  // 입력 완료 후 키보드 숨기기 (선택 사항)
                  FocusScope.of(context).unfocus();
                 },
                 decoration: InputDecoration(
                  hintText: '배달음식점 링크를 공유해 보세요',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none, // Remove default TextField border
                  isDense: true, // Reduce vertical space
                  contentPadding: EdgeInsets.zero, // Remove default content padding
                  fillColor: Colors.transparent,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10), // Spacing between text field and icon
            InkWell(
              onTap: (){},
              child: Image.asset(
                'assets/link.png', 
                width: 20, 
                height: 20,
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

}
