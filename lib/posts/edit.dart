import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택을 위해 추가
import 'dart:io'; // File 클래스를 위해 추가
import 'package:image_cropper/image_cropper.dart'; // image_cropper 패키지 임포트
import 'package:reorderable_grid_view/reorderable_grid_view.dart'; // reorderable_grid_view 패키지 임포트

class EditPage extends StatefulWidget {
  final List<XFile>? initialFiles;

  const EditPage({super.key, this.initialFiles});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  List<XFile> _selectedImages = []; // 사용자가 선택하고 편집할 이미지 리스트

  @override
  void initState() {
    super.initState();
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      _selectedImages = List.from(widget.initialFiles!); // 초기 이미지 설정
    } else {
      _pickImages(); // 초기 이미지가 없으면 여러 이미지 선택기 실행
    }
  }

  // 갤러리에서 여러 이미지를 선택하는 함수
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(); // 여러 이미지 선택

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images; // 선택된 이미지들로 업데이트
      });
    } else {
      // 이미지가 선택되지 않았을 경우, 현재 화면을 닫고 이전 화면으로 돌아갑니다.
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // 특정 인덱스의 이미지를 자르는 함수
  Future<void> _cropImage(int index) async {
    if (index < 0 || index >= _selectedImages.length) return;

    final XFile imageToCrop = _selectedImages[index];

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageToCrop.path, // 자를 이미지의 경로
      compressFormat: ImageCompressFormat.png, // 압축 형식 지정
      compressQuality: 90, // 압축 품질
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: '이미지 자르기',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original, // 초기 자르기 비율
            lockAspectRatio: false), // 비율 고정 여부
        IOSUiSettings(
          title: '이미지 자르기',
          doneButtonTitle: '완료',
          cancelButtonTitle: '취소',
        ),
        // 웹 UI 설정은 주석 처리 유지 (이전 오류 해결 위함)
        // WebUiSettings(
        //   context: context,
        //   presentStyle: 'dialog',
        //   boundaryWidth: 520,
        //   boundaryHeight: 520,
        //   viewportWidth: 480,
        //   viewportHeight: 480,
        //   viewportType: 'circle',
        //   enableExif: true,
        //   enableZoom: true,
        //   showZoomer: true,
        // ),
      ],
    );

    if (croppedFile != null) {
      // 자르기가 성공하면 CroppedFile을 XFile로 변환하여 해당 인덱스의 이미지를 업데이트
      setState(() {
        _selectedImages[index] = XFile(croppedFile.path);
      });
    } else {
      print('이미지 자르기 취소됨');
    }
  }

  // 드래그 앤 드롭으로 이미지 순서를 변경하는 콜백
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final XFile item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 전체 배경색
      appBar: AppBar(
        backgroundColor: Colors.black, // 앱 바 배경색
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new, 
            color: Colors.white,
            size: 18,
          ), // 뒤로 가기 아이콘
          onPressed: () {
            Navigator.of(context).pop(); // 뒤로 가기 버튼 동작 (편집 취소)
          },
        ),
        title: const Text(
          '끌어서 순서 변경', // 앱 바 제목
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,

          ),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _selectedImages.isNotEmpty
                  // ReorderableGridView.builder는 children 대신 itemBuilder와 itemCount를 사용합니다.
                  ? ReorderableGridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 한 줄에 3개 이미지
                        crossAxisSpacing: 4, // 가로 간격
                        mainAxisSpacing: 4, // 세로 간격
                        childAspectRatio: 1.0, // 정사각형 비율
                      ),
                      onReorder: _onReorder, // 순서 변경 콜백
                      itemCount: _selectedImages.length, // 아이템 개수
                      itemBuilder: (context, index) { // 아이템 빌더
                        final imageFile = _selectedImages[index];
                        return GestureDetector(
                          key: ValueKey(imageFile.path), // ReorderableGridView를 위한 고유 키
                          onTap: () => _cropImage(index), // 이미지 탭 시 자르기 창 열기
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(0.0), // 둥근 모서리
                                  child: Image.file(
                                    File(imageFile.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // 이미지 번호 표시
                              Positioned(
                                top: 0, // 약간의 여백을 주어 너무 붙지 않도록
                                left: 4, // 약간의 여백을 주어 너무 붙지 않도록
                                child: Container(
                                  padding: const EdgeInsets.all(5), // 이 패딩은 유지하여 원 안의 여백을 줍니다.
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(225, 251, 169, 1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              // 이미지 삭제 버튼
                              Positioned(
                                top: -10, // 음수 값을 주어 위로 더 당깁니다.
                                right: -10, // 음수 값을 주어 오른쪽으로 더 당깁니다.
                                child: IconButton(
                                  padding: EdgeInsets.zero, // IconButton의 기본 패딩 제거
                                  constraints: const BoxConstraints(), // IconButton의 최소 크기 제약 제거
                                  icon: const Icon(Icons.cancel, color: Colors.white, size: 19),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white), // 이미지 로딩 중
                    ),
            ),
          ),
          // 하단 "다음" 버튼
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity, // 너비를 최대로 확장
              height: 50, // 높이 고정
              child: ElevatedButton(
                onPressed: _selectedImages.isNotEmpty
                    ? () {
                        // "다음" 버튼 클릭 시 편집된 이미지 리스트를 이전 화면으로 반환
                        Navigator.of(context).pop(_selectedImages);
                      }
                    : null, // 이미지가 없으면 버튼 비활성화
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(240, 240, 240, 1), // 버튼 배경색
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // 둥근 모서리
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15), // 내부 패딩
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
