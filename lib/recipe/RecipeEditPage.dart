// lib/recipe/RecipeEditPage.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/Recipe.dart';
import '../models/PostInputData.dart';
import '../create/ConfirmPage.dart';
import '../create/helpers/ImagePickerFlow.dart';
import 'dart:convert';

final apiKey = dotenv.env['OPENAI_API_KEY']!;

// *******************************************************************
// 1. 모델 정의 및 GPT 통신 로직 (변경 없음)
// *******************************************************************

const String recipeEditSystemPrompt = """
당신은 요리 레시피를 자연스럽게 개선하는 조리 도우미입니다.

- 사용자의 메시지(message)를 기반으로, 제공된 recipe JSON을 최소한으로 수정하십시오.
- 재료, 계량, 조리 순서 등 필요한 부분만 변경하거나 추가/삭제합니다.
- 가능한 한 원본 구조를 유지하고, 같은 필드명을 그대로 유지합니다.
- JSON만 반환하세요. 다른 설명은 절대 포함하지 마세요.
""";

// LlmModel? _llmModel;
// LlmSession? _llmSession;

// Future<void> initLlm() async {
//   _llmModel = await LlmModel.create(
//     modelPath: 'assets/models/gemma-2b-it.bin',
//     maxTokens: 1024,
//     temperature: 0.7,
//   );

//   _llmSession = _llmModel!.createSession();
// }

// Future<Recipe?> sendRecipeEditRequestOnDevice({
//   required Recipe recipe,
//   required String message,
// }) async {
//   if (_llmInference == null) {
//     print("ERROR: LLM 모델이 초기화되지 않았습니다.");
//     return null;
//   }

//   // 1. 현재 레시피 JSON
//   final currentRecipeJson = jsonEncode(recipe.toJson());

//   // 2. LLM에 전달할 프롬프트
//   final fullPrompt = """
// $recipeEditSystemPrompt
// ---
// ## 입력 정보

// ### 1. 현재 레시피 JSON (절대 수정 금지):
// $currentRecipeJson

// ### 2. 수정 요청 메시지:
// $message

// ## 출력 지시사항 (반드시 준수)
// - 위 요청을 반영하여 레시피를 최소한으로 수정하세요.
// - 반드시 JSON **데이터만** 출력하세요.
// - 설명, 마크다운, 텍스트를 절대 포함하지 마세요.

// ### 출력 형식:
// {
//   "recipe": {
//     // 수정된 레시피 데이터
//   }
// }
// """;

//   print("모델에 전송할 프롬프트 길이: ${fullPrompt.length}");

//   String content = "";

//   try {
//     // 3. 온디바이스 LLM 호출
//     final response = await _llmInference!.generateResponse(fullPrompt);
//     content = response.text.trim();

//     print("Raw Content from LLM: $content");

//     // 4. 마크다운 코드 블록 제거 (```json, ```)
//     content = content
//         .replaceFirst(RegExp(r'^```json\s*'), '')
//         .replaceFirst(RegExp(r'^```\s*'), '')
//         .replaceFirst(RegExp(r'\s*```$'), '')
//         .trim();

//     // 5. JSON 형식 검증
//     if (!content.startsWith('{') || !content.endsWith('}')) {
//       throw FormatException("유효한 JSON 객체가 아닙니다.");
//     }

//     // 6. JSON 파싱
//     final jsonResult = jsonDecode(content);

//     if (jsonResult is Map && jsonResult.containsKey('recipe')) {
//       return Recipe.fromJson(jsonResult['recipe']);
//     } else {
//       throw FormatException("'recipe' 키가 존재하지 않습니다.");
//     }
//   } catch (e) {
//     print(
//       "온디바이스 LLM JSON 파싱 오류: $e\n"
//       "문제의 Content:\n$content",
//     );
//     return null;
//   }
// }


Future<Recipe?> sendRecipeEditRequest({
  required Recipe recipe,
  required String message,
}) async {

  final payload = {
    "model": "gpt-4o-mini",
    "messages": [
      {"role": "system", "content": recipeEditSystemPrompt},
      {
        "role": "user",
        "content": jsonEncode({
          "recipe": recipe.toJson(),
          "message": message,
        })
      }
    ],
    "response_format": {"type": "json_object"}
  };

  final response = await http.post(
    Uri.parse("https://api.openai.com/v1/chat/completions"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
    },
    body: jsonEncode(payload),
  );
  // print(response.statusCode);

  if (response.statusCode != 200) {
    print("GPT ERROR: ${response.body}");
    return null;
  }

  final data = jsonDecode(response.body);
  // print("data: ${data}");
  final content = data["choices"][0]["message"]["content"];
  // print("content: ${content}");
  try {
    final jsonResult = jsonDecode(content);
    // print("jsonResult: ${jsonResult}");
    return Recipe.fromJson(jsonResult['recipe']);
  } catch (e) {
    print("JSON parse error: $e\ncontent=$content");
    return null;
  }
}

// 편집 가능한 재료 모델
class IngredientEdit {
  String name;
  String quantity;
  bool isModified;

  IngredientEdit({
    required this.name,
    required this.quantity,
    this.isModified = false,
  });
}

// 편집 가능한 조리법 모델
class MethodEdit {
  String describe;
  bool isModified;

  MethodEdit({
    required this.describe,
    this.isModified = false,
  });
}

// *******************************************************************
// 2. 메인 위젯
// *******************************************************************

class RecipeEditPage extends StatefulWidget {
  final Recipe? recipe;

  const RecipeEditPage({super.key, required this.recipe});

  @override
  State<RecipeEditPage> createState() => _RecipeEditPageState();
}

class _RecipeEditPageState extends State<RecipeEditPage> {
  final PageController _imageController = PageController();
  final TextEditingController _notesController = TextEditingController();
  final List<File> _capturedImages = [];
  late Recipe? _currentRecipe;

  // 수정 가능한 리스트 (State 내에서 관리)
  final List<IngredientEdit> _editableIngredients = [];
  final List<MethodEdit> _editableMethods = [];

  bool _showOriginalRecipe = false;
  bool _showRecipeDetails = false; // For expanding recipe card

  // Speech recognition
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();

    _currentRecipe = widget.recipe; // 원본 레시피 복사

    // 원본 데이터를 편집 가능한 리스트로 복사
    if (_currentRecipe != null){
      _initializeEditableLists(_currentRecipe!);
    }

    // Initialize speech
    Future.delayed(const Duration(milliseconds: 500), _initSpeech);
  }

  void _initializeEditableLists(Recipe recipe) {
    _editableIngredients
      ..clear()
      ..addAll(recipe.ingredients.map((ing) => IngredientEdit(
            name: ing.name,
            quantity: ing.quantity,
          )));

    _editableMethods
      ..clear()
      ..addAll(recipe.methods.map((method) => MethodEdit(
            describe: method.describe,
          )));
  }

  void _applyRecipeUpdate(Recipe updated) {
    setState(() {
      _currentRecipe = updated;
      _initializeEditableLists(updated);
    });
  }

  // *******************************************************************
  // 3. 음성 인식 및 GPT 로직
  // *******************************************************************

  Future<void> _initSpeech() async {
    if (!mounted) return;

    try {
      _speech = stt.SpeechToText();
      final available = await _speech!.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            // 듣기 종료 시 자동으로 _stopListening 호출
            _stopListening(manualStop: false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          debugPrint('Speech error: ${error.errorMsg}');
          setState(() => _isListening = false);
        },
        debugLogging: false,
      );

      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
      }
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _speech = null;
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || _speech == null || _isListening) return;

    try {
      setState(() => _isListening = true);

      final locales = await _speech!.locales();
      final koreanLocale = locales.firstWhere(
        (locale) => locale.localeId.startsWith('ko'),
        orElse: () => locales.first,
      );

      await _speech!.listen(
        onResult: (result) {
          if (!mounted) return;

          if (result.finalResult) {
            final recognizedText = result.recognizedWords;
            if (recognizedText.isNotEmpty) {
              setState(() {
                final currentText = _notesController.text;
                _notesController.text = currentText.isEmpty
                    ? recognizedText
                    : '$currentText $recognizedText';
                _notesController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _notesController.text.length),
                );
              });
            }
          }
        },
        localeId: koreanLocale.localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Error starting speech: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성 인식을 시작할 수 없습니다')),
        );
      }
    }
  }

  Future<void> _stopListening({bool manualStop = true}) async {
    if (_speech == null) return;

    try {
      await _speech!.stop();
    } catch (e) {
      debugPrint("Speech stop error: $e");
    } finally {
      if (!mounted) return;

      setState(() => _isListening = false);

      final msg = _notesController.text.trim();

      // 수동으로 중지했거나, 텍스트가 있을 때만 GPT 호출
      if (msg.isEmpty || !manualStop) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("레시피 개선 요청 중...")),
      );
      if (_currentRecipe != null) {
        final updated = await sendRecipeEditRequest(
          recipe: _currentRecipe!,
          message: msg,
        );
        
        if (updated != null) {
          _applyRecipeUpdate(updated);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("레시피가 음성 명령에 따라 업데이트되었습니다!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("레시피 업데이트에 실패했습니다.")),
          );
        }
      }
    }
  }

  // *******************************************************************
  // 4. 리소스 해제 및 UI 헬퍼
  // *******************************************************************

  @override
  void dispose() {
    _imageController.dispose();
    _notesController.dispose();
    if (_isListening && _speech != null) {
      _speech!.stop();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final flow = ImagePickerFlow();
    final result = await flow.pickAndEdit(context);
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _capturedImages.addAll(result.files);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _addIngredient() {
    setState(() {
      _editableIngredients.add(IngredientEdit(
        name: '',
        quantity: '',
        isModified: true,
      ));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _editableIngredients.removeAt(index);
    });
  }

  void _addMethod() {
    setState(() {
      _editableMethods.add(MethodEdit(
        describe: '',
        isModified: true,
      ));
    });
  }

  void _removeMethod(int index) {
    setState(() {
      _editableMethods.removeAt(index);
    });
  }

  void _insertMethodAt(int index) {
    setState(() {
      _editableMethods.insert(index, MethodEdit(
        describe: '',
        isModified: true,
      ));
    });
  }

  Widget _buildIngredientsGrid() {
    final halfLength = (_editableIngredients.length / 2).ceil();
    final leftColumn = _editableIngredients.sublist(0, halfLength);
    final rightColumn = _editableIngredients.length > halfLength
        ? _editableIngredients.sublist(halfLength)
        : <IngredientEdit>[];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftColumn.asMap().entries.map((entry) {
              final index = entry.key;
              final ing = entry.value;
              return IngredientEditor(
                key: ValueKey('ingredient_$index'),
                index: index,
                ingredient: ing,
                onRemove: () => _removeIngredient(index),
                onUpdate: () => setState(() {}), // 변경 사항 반영을 위해 setState 호출
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rightColumn.asMap().entries.map((entry) {
              final index = halfLength + entry.key;
              final ing = entry.value;
              return IngredientEditor(
                key: ValueKey('ingredient_$index'),
                index: index,
                ingredient: ing,
                onRemove: () => _removeIngredient(index),
                onUpdate: () => setState(() {}), // 변경 사항 반영을 위해 setState 호출
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMethodsWithDividers() {
    List<Widget> widgets = [];

    for (int i = 0; i < _editableMethods.length; i++) {
      // Add the method
      widgets.add(MethodStepEditor(
        key: ValueKey('method_$i'),
        index: i,
        method: _editableMethods[i],
        onRemove: () => _removeMethod(i),
        onUpdate: () => setState(() {}), // 변경 사항 반영을 위해 setState 호출
      ));

      // Add clickable divider line between steps (not after the last one)
      if (i < _editableMethods.length - 1) {
        widgets.add(
          InkWell(
            onTap: () => _insertMethodAt(i + 1),
            child: Container(
              height: 24,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[700],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  String _buildPostContent() {
    final buffer = StringBuffer();

    // 레시피 제목
    if (_currentRecipe != null) {
      buffer.writeln('레시피: ${_currentRecipe!.title}\n');
    }
    else {
      buffer.writeln('레시피를 먼저 선택해주세요.\n');
    }

    // 재료 (수정된 것만 또는 전체)
    // 원본 코드에서 수정된 것만 출력하도록 했으므로 그대로 유지
    final modifiedIngredients = _editableIngredients.where((ing) => ing.isModified).toList();
    if (modifiedIngredients.isNotEmpty) {
      buffer.writeln('📝 재료 수정:');
      for (var ing in modifiedIngredients) {
        buffer.writeln('• ${ing.name}: ${ing.quantity}');
      }
      buffer.writeln();
    }

    // 조리법 (수정된 것만 또는 전체)
    final modifiedMethods = _editableMethods.where((method) => method.isModified).toList();
    if (modifiedMethods.isNotEmpty) {
      buffer.writeln('👨‍🍳 조리법 수정:');
      for (int i = 0; i < modifiedMethods.length; i++) {
        buffer.writeln('${i + 1}. ${modifiedMethods[i].describe}');
      }
      buffer.writeln();
    }

    // 사용자 메모
    if (_notesController.text.trim().isNotEmpty) {
      buffer.writeln('💭 요리 후기:');
      buffer.writeln(_notesController.text.trim());
    }

    return buffer.toString();
  }

  Future<void> _submitPost() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요리한 음식 사진을 최소 1장 추가해주세요.')),
      );
      return;
    }

    // PostInputData 생성
    final postInput = PostInputData(imageFiles: _capturedImages);
    postInput.selectedCategory = '요리';
    postInput.selectedValue = 'Recipe';
    postInput.recommendRecipe = true;
    postInput.textController.text = _buildPostContent();
    postInput.capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(DateTime.now());

    // ConfirmPage로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmPage(postInputs: [postInput]),
      ),
    );

    if (result == true && mounted) {
      // 업로드 성공 시 2단계 뒤로 가기 (RecipeDetailPage도 닫기)
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: const Text(
          '요리 기록하기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOriginalRecipe ? Icons.edit : Icons.menu_book,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _showOriginalRecipe = !_showOriginalRecipe;
              });
            },
            tooltip: _showOriginalRecipe ? '편집 모드' : '원본 레시피 보기',
          ),
        ],
      ),
      body: _showOriginalRecipe ? _buildOriginalRecipeView() : _buildEditView(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _submitPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurface,
              foregroundColor: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '게시글 작성 완료',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalRecipeView() {
    if (widget.recipe == null)
      return ListView(); 

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 원본 레시피 이미지
      
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.recipe!.images.originalUrl,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, size: 80),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // 레시피 제목
        Text(
          widget.recipe!.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // 팁
        if (widget.recipe!.tips.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 ${widget.recipe!.tips}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: 24),

        // 재료
        const Text(
          '재료',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...widget.recipe!.ingredients.map((ing) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('• ${ing.name}: ${ing.quantity}'),
        )),
        const SizedBox(height: 24),

        // 조리법
        const Text(
          '조리법',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...widget.recipe!.methods.asMap().entries.map((entry) {
          final index = entry.key;
          final method = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${method.describe}',
                  style: const TextStyle(fontSize: 16),
                ),
                if (method.image.originalUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        method.image.originalUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEditView() {
    final bool hasNotes = _notesController.text.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // 원본 레시피 정보 카드 (확장 가능)
        _buildRecipeInfoCard(),

        const SizedBox(height: 24),

        // Large voice recording button with Siri-like animation
        if (_speechAvailable)
          _buildVoiceInputSection(hasNotes),

        // Show text field only if there's content or user is not using voice
        if (hasNotes || !_speechAvailable) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '요리하면서 느낀 점, 맛 평가, 팁 등을 자유롭게 작성해주세요. (여기에 음성 인식 결과가 나타납니다)',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) async {
              // 직접 입력 후 엔터/완료 시에도 GPT 호출 가능
              if (value.trim().isNotEmpty && (_currentRecipe != null)) {
                final updated = await sendRecipeEditRequest(
                  recipe: _currentRecipe!,
                  message: value.trim(),
                );
                if (updated != null) {
                  _applyRecipeUpdate(updated);
                  _notesController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("레시피가 텍스트 명령에 따라 업데이트되었습니다!")),
                  );
                }
              }
            },
          ),
        ],
        const SizedBox(height: 10),

        // 요리 사진 섹션
        _buildImagePickerSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecipeInfoCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showRecipeDetails = !_showRecipeDetails;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.recipe?.title ?? '레시피 제목 없음',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  _showRecipeDetails ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
            if (widget.recipe != null) 
              if (widget.recipe!.tips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '💡 ${widget.recipe!.tips}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
                ),
              ],
            // 재료 및 조리법 수정 섹션 (확장 시 표시)
            if (_showRecipeDetails) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // 재료 수정 섹션
              _buildIngredientEditSection(),
              const SizedBox(height: 16),

              // 조리법 수정 섹션
              _buildMethodEditSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _addIngredient,
              icon: Icon(Icons.add_circle_outline, size: 22, color: Colors.white),
              tooltip: '재료 추가',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_editableIngredients.isNotEmpty)
          _buildIngredientsGrid(),
      ],
    );
  }

  Widget _buildMethodEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Directions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _addMethod,
              icon: Icon(Icons.add_circle_outline, size: 22, color: Colors.white),
              tooltip: '조리법 추가',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._buildMethodsWithDividers(),
      ],
    );
  }

  Widget _buildVoiceInputSection(bool hasNotes) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isListening ? 120 : 100,
              height: _isListening ? 120 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isListening
                    ? LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.purple.shade400,
                          Colors.pink.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade700,
                          Colors.grey.shade600,
                        ],
                      ),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: _isListening ? 50 : 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isListening ? '듣는 중... 탭하여 중지' : '탭하여 음성으로 입력',
                style: TextStyle(
                  fontSize: 14,
                  color: _isListening ? Colors.blue.shade300 : Colors.grey[500],
                  fontWeight:
                      _isListening ? FontWeight.w600 : FontWeight.normal,
                ),
              ),

              if (!_isListening) ...[
                const SizedBox(width: 8),
                Text('|', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 8),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      // 텍스트 필드를 보여주기 위해 강제로 노트에 내용 추가 (나중에 사용자가 지우도록)
                      _notesController.text = ' ';
                    });
                  },
                  child: Text(
                    '직접 입력',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: _capturedImages.isEmpty
          ? InkWell(
              onTap: _pickImages,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    '요리 완성 사진 추가',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                PageView.builder(
                  controller: _imageController,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _capturedImages[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // 추가 버튼
                      InkWell(
                        onTap: _pickImages,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 삭제 버튼
                      if (_capturedImages.isNotEmpty)
                        InkWell(
                          onTap: () {
                            // 현재 페이지 인덱스 가져오기
                            final currentPage = _imageController.page?.round() ?? 0;
                            // 삭제 후 PageView가 crash 나지 않도록 조정
                            if (currentPage > 0 && currentPage == _capturedImages.length - 1) {
                              _imageController.animateToPage(
                                currentPage - 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              );
                            }
                            _removeImage(currentPage);
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_capturedImages.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // PageController를 사용하여 현재 페이지를 나타내는 인디케이터를 만들어야 하지만,
                      // 간단한 리팩토링이므로 정적 인디케이터만 남겨둡니다.
                      children: List.generate(
                        _capturedImages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.7),
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

// *******************************************************************
// 5. 추출된 보조 위젯 (IngredientEditor)
// *******************************************************************

class IngredientEditor extends StatefulWidget {
  final int index;
  final IngredientEdit ingredient;
  final VoidCallback onRemove;
  final VoidCallback onUpdate; // 상태 변경을 부모에게 알리기 위한 콜백

  const IngredientEditor({
    super.key,
    required this.index,
    required this.ingredient,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends State<IngredientEditor> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    _quantityController = TextEditingController(text: widget.ingredient.quantity);

    // 컨트롤러 리스너를 통해 상태 업데이트
    _nameController.addListener(() => _updateIngredient(isName: true));
    _quantityController.addListener(() => _updateIngredient(isName: false));
  }

  void _updateIngredient({required bool isName}) {
    // 변경된 값이 실제로 다를 때만 업데이트 (불필요한 rebuild 방지)
    final currentValue = isName ? _nameController.text : _quantityController.text;
    final modelValue = isName ? widget.ingredient.name : widget.ingredient.quantity;

    if (currentValue != modelValue) {
      setState(() {
        if (isName) {
          widget.ingredient.name = currentValue;
        } else {
          widget.ingredient.quantity = currentValue;
        }
        widget.ingredient.isModified = true;
      });
      // 부모에게 변경 사항을 알림
      widget.onUpdate();
    }
  }


  @override
  void didUpdateWidget(covariant IngredientEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부 데이터 변경 시 컨트롤러 업데이트 (예: GPT 응답 후)
    if (oldWidget.ingredient != widget.ingredient) {
      if (_nameController.text != widget.ingredient.name) {
        _nameController.text = widget.ingredient.name;
      }
      if (_quantityController.text != widget.ingredient.quantity) {
        _quantityController.text = widget.ingredient.quantity;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;

    return Container(
      // 수정된 경우 배경색을 연한 노란색/주황색 계열로 지정
      color: ing.isModified ? Colors.amber.withOpacity(0.05) : Colors.transparent, 
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // 패딩 추가
      margin: const EdgeInsets.only(bottom: 4), // 마진은 유지
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point (색상 로직은 그대로 유지)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: ing.isModified ? Colors.amber[600] : Colors.grey[500],
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ingredient name (텍스트 색상은 그대로 유지)
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: ing.isModified ? Colors.amber[100] : Colors.grey[300],
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'ingredient',
                      hintStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '|',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey[400],
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'amount',
                      hintStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              onTap: widget.onRemove,
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// *******************************************************************
// 6. 추출된 보조 위젯 (MethodStepEditor)
// *******************************************************************

class MethodStepEditor extends StatefulWidget {
  final int index;
  final MethodEdit method;
  final VoidCallback onRemove;
  final VoidCallback onUpdate; // 상태 변경을 부모에게 알리기 위한 콜백

  const MethodStepEditor({
    super.key,
    required this.index,
    required this.method,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<MethodStepEditor> createState() => _MethodStepEditorState();
}

class _MethodStepEditorState extends State<MethodStepEditor> {
  late TextEditingController _describeController;

  @override
  void initState() {
    super.initState();
    _describeController = TextEditingController(text: widget.method.describe);
    _describeController.addListener(_updateMethod);
  }

  void _updateMethod() {
    final currentValue = _describeController.text;
    if (currentValue != widget.method.describe) {
      setState(() {
        widget.method.describe = currentValue;
        widget.method.isModified = true;
      });
      widget.onUpdate();
    }
  }

  @override
  void didUpdateWidget(covariant MethodStepEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.method != widget.method && _describeController.text != widget.method.describe) {
      _describeController.text = widget.method.describe;
    }
  }

  @override
  void dispose() {
    _describeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.method;

    return Container(
      // 수정된 경우 배경색을 연한 주황색/빨간색 계열로 지정
      color: method.isModified ? Colors.red.withOpacity(0.05) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), // 패딩 추가
      margin: const EdgeInsets.only(bottom: 8), // 마진은 유지
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number (텍스트 색상은 그대로 유지)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              '${widget.index + 1}.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.6,
                color: method.isModified ? Colors.orange[400] : Colors.grey[400],
              ),
            ),
          ),
          // Method description (텍스트 색상은 그대로 유지)
          Expanded(
            child: TextField(
              controller: _describeController,
              maxLines: null,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: method.isModified ? Colors.orange[100] : Colors.grey[300],
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 4),
                hintText: 'Describe this step of the recipe...',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: InkWell(
              onTap: widget.onRemove,
              child: Icon(
                Icons.close,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}