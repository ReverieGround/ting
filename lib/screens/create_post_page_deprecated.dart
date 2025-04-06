import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ✅ 이미지 선택을 위한 패키지 추가
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:developer'; // log() 사용을 위해 추가
import '../services/auth_service.dart';
import '../config.dart';
import '../widgets/common/vibe_header.dart'; 

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String visibility = 'PUBLIC'; 
  List<String> imageUrls = [];
  bool isPrivate = false;
  final ImagePicker _picker = ImagePicker(); // ✅ 이미지 선택기 추가

  /// ✅ 사용자 이미지 선택 (갤러리)
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageUrls.add(image.path); // 파일 경로 추가
      });
    }
  }

  /// ✅ 이미지 업로드 함수 (서버 업로드 예시)
  Future<String?> uploadImage(File imageFile) async {
    String? token = await AuthService.getToken();
    if (token == null) return null;
    
    var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/post/upload_image'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);
      return jsonResponse['image_url']; // 서버에서 반환한 이미지 URL
    } else {
      return null;
    }
  }

  /// ✅ 게시물 업로드
  Future<void> uploadPost() async {
    if (!mounted) return;

    String? token = await AuthService.getToken();
    if (token == null) return;
    
    List<String> uploadedImageUrls = [];
    for (String imagePath in imageUrls) {
      String? imageUrl = await uploadImage(File(imagePath)); // 이미지 업로드
      
      if (imageUrl != null) {
        uploadedImageUrls.add(imageUrl);
      }
    }

    final response = await http.post(
      Uri.parse('${Config.baseUrl}/post/upload'),
      body: jsonEncode({
        'title': titleController.text,
        'content': contentController.text,
        'visibility': isPrivate ? 'PRIVATE' : 'PUBLIC',
        'image_urls': uploadedImageUrls.isEmpty ? null : uploadedImageUrls,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시물 업로드 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VibeHeader(
        titleWidget: Text(
          '게시물 작성',
          style:TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      // AppBar(title: Text('게시물 작성')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: '제목')),
            SizedBox(height: 12),
            TextField(controller: contentController, decoration: InputDecoration(labelText: '내용')),
            SizedBox(height: 20),

            /// ✅ 이미지 추가 버튼
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.image),
              label: Text('이미지 추가'),
            ),

            /// ✅ 선택된 이미지 미리보기
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Image.file(File(imageUrls[index]), width: 100, height: 100, fit: BoxFit.cover),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                imageUrls.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Checkbox(
                  value: isPrivate,
                  onChanged: (bool? newValue) {
                    setState(() {
                      isPrivate = newValue ?? false;
                    });
                  },
                ),
                Text('비공개', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 20),

            /// ✅ 게시하기 버튼
            ElevatedButton(onPressed: uploadPost, child: Text('게시하기')),
          ],
        ),
      ),
    );
  }
}
