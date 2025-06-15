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
import '../../widgets/common/vibe_header.dart'; 
import '../services/auth_service.dart';
import '../config.dart';
import '../screens/image_edit_page.dart';

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
  int _currentIndex = 0;
  bool isUploading = false;
  final List<String> mealNames = ['아침', '점심', '저녁'];
  final List<String> categories = ['🍳 요리', '🍱 밀키트', '🏤 식당', '🛵 배달'];
  final List<String> emojis = ['🔥 Fire', '😋 Tasty', '🤔 So-so', '😑 Womp'];

  final List<_PostInputData> postInputs = List.generate(3, (_) => _PostInputData());
  final ImagePicker _picker = ImagePicker();

  DateTime selectedDate = DateTime.now();
  String get formattedDate => DateFormat('yyyy. MM. dd HH:mm').format(selectedDate);

  Future<void> pickCustomDateTime(BuildContext context, _PostInputData currentInput) async {
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
                        firstDate: DateTime(2020),
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
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: hour,
                          items: List.generate(24, (i) => DropdownMenuItem(
                            value: i, child: Text('$i시'),
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
                        ),
                        DropdownButton<int>(
                          value: minute,
                          items: List.generate(60, (i) => DropdownMenuItem(
                            value: i, child: Text('$i분'),
                          )),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            if (tempPicked != selectedDate) {
                              // setState(() => selectedDate = tempPicked);
                              setState(() => currentInput.capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(tempPicked));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('저장'),
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

  Future<void> pickImage(int index) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    // 1. 이미지 회전 보정
    final File? editedFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditPage(originalFile: File(picked.path)),
      ),
    );
    if (editedFile == null) return;
    // 2. EXIF에서 촬영 일자 추출
    final DateTime? takenAt = await extractImageDate(editedFile);
    if (takenAt != null) {
      setState(() {
        postInputs[index].capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(takenAt);
      });
    }
    // 3. 회전 보정된 이미지 저장
    setState(() {
      postInputs[index].imageFile = editedFile;
    });
  }

  Future<String?> uploadImageToFirebase(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ 로그인된 사용자 없음");
        return null;
      }
      final fileName = 'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.${file.path.split('.').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      debugPrint("✅ Firebase Storage 업로드 성공: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Firebase 이미지 업로드 실패: $e");
      return null;
    }
  }

  Future<void> uploadAllPosts() async {
    setState(() => isUploading = true); // 로딩 시작
    bool uploaded = false;

    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => isUploading = false);
      return;
    }

    for (int i = 0; i < postInputs.length; i++) {
      final input = postInputs[i];
      if (input.imageFile == null || input.content.trim().isEmpty) continue;

      final imageUrl = await uploadImageToFirebase(input.imageFile!);
      if (imageUrl == null) continue;

      final payload = {
        "title": "${mealNames[i]} 식사",
        "content": input.content,
        "image_urls": [imageUrl],
        "visibility": "PUBLIC",
        "recipe_id": input.recommendRecipe ? "some-recipe-id" : null,
      };
      debugPrint('${Config.baseUrl}/post/upload');
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/post/upload'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        uploaded = true;
      }

      debugPrint("[$i] 업로드 상태: ${res.statusCode}, 응답: ${res.body}");
    }

    if (mounted) {
      setState(() => isUploading = false); // 로딩 종료
    }

    if (uploaded && mounted) {
      Navigator.pop(context, true);
    }
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
  Widget build(BuildContext context) {
    final currentInput = postInputs[_currentIndex];
    return Scaffold(
      appBar: VibeHeader(
        backgroundColor: Colors.white,
        titleWidget: const Text(
          "Yum 업로드", 
          style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        )
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
                      value = (1 - (value * 0.2)).clamp(0.8, 1.0); // 0.8~1.0 사이 scale
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: value,
                          child: GestureDetector(
                            onTap: () => pickImage(index),
                            child: Container(
                              height: 180,
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
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => pickCustomDateTime(context, currentInput),
                          child: Text(
                            currentInput.capturedDate,
                            style: const TextStyle(
                              fontSize: 16, 
                              color: Colors.black87
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
                  // Text("${mealNames[_currentIndex]} 입력", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "카테고리", 
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    )
                  ),
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
                              currentInput.selectedCategory = isSelected ? null : e;
                            });
                          },
                          selectedColor: Colors.grey.shade600,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          showCheckmark: false,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color:Colors.white,
                    child: Row(
                      children: [
                        Text(
                        "셀프 평가", 
                        style: const TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        )
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(16), // ✅ ripple 범위 설정
                        onTap: () {
                          setState(() => currentInput.recommendRecipe = !currentInput.recommendRecipe);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.transparent, // ✅ border 제거 (또는 강조용 설정)
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "추천",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.thumb_up,
                                size: 11,
                                color: currentInput.recommendRecipe ? Colors.amber : Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: emojis.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final e = emojis[index];
                        final isSelected = currentInput.selectedEmoji == e;
                        return ChoiceChip(
                          label: Text(e),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => currentInput.selectedEmoji = e);
                          },
                          selectedColor: Colors.grey.shade600,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          

          // ✅ 업로드 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading ? null : uploadAllPosts, // ⛔ 업로드 중이면 눌리지 않도록
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _PostInputData {
  File? imageFile;
  String? selectedEmoji;
  String? selectedCategory;
  String capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(DateTime.now());
  bool recommendRecipe = false;
  TextEditingController textController = TextEditingController();
  String get content => textController.text;
}
