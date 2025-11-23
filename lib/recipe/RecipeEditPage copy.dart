// lib/recipe/RecipeEditPage.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/Recipe.dart';
import '../models/PostInputData.dart';
import '../create/ConfirmPage.dart';
import '../create/helpers/ImagePickerFlow.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String recipeEditSystemPrompt = """
당신은 요리 레시피를 자연스럽게 개선하는 조리 도우미입니다.

- 사용자의 메시지(message)를 기반으로, 제공된 recipe JSON을 최소한으로 수정하십시오.
- 재료, 계량, 조리 순서 등 필요한 부분만 변경하거나 추가/삭제합니다.
- 가능한 한 원본 구조를 유지하고, 같은 필드명을 그대로 유지합니다.
- JSON만 반환하세요. 다른 설명은 절대 포함하지 마세요.
""";


Future<Recipe?> sendRecipeEditRequest({
  required Recipe recipe,
  required String message,
}) async {
  const apiKey = "YOUR_OPENAI_API_KEY";

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

  if (response.statusCode != 200) {
    print("GPT ERROR: ${response.body}");
    return null;
  }

  final data = jsonDecode(response.body);
  final content = data["choices"][0]["message"]["content"];

  try {
    final jsonResult = jsonDecode(content);
    return Recipe.fromJson(jsonResult);
  } catch (e) {
    print("JSON parse error: $e\ncontent=$content");
    return null;
  }
}

class RecipeEditPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeEditPage({super.key, required this.recipe});

  @override
  State<RecipeEditPage> createState() => _RecipeEditPageState();
}

class _RecipeEditPageState extends State<RecipeEditPage> {
  final PageController _imageController = PageController();
  final TextEditingController _notesController = TextEditingController();
  final List<File> _capturedImages = [];
  late Recipe _currentRecipe;

  // 수정 가능한 재료 리스트
  final List<IngredientEdit> _editableIngredients = [];

  // 수정 가능한 조리법 리스트
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

    _currentRecipe = widget.recipe;  // 복사!

    // Initialize speech with extra safety for simulators
    // Delay initialization to not block UI
    Future.delayed(const Duration(milliseconds: 500), _initSpeech);

    // 원본 재료를 편집 가능한 리스트로 복사
    _editableIngredients.addAll(
      widget.recipe.ingredients.map((ing) => IngredientEdit(
        name: ing.name,
        quantity: ing.quantity,
        isModified: false,
      ))
    );

    // 원본 조리법을 편집 가능한 리스트로 복사
    _editableMethods.addAll(
      widget.recipe.methods.map((method) => MethodEdit(
        describe: method.describe,
        isModified: false,
      ))
    );
  }

  void _applyRecipeUpdate(Recipe updated) {
    setState(() {
      _currentRecipe = updated;

      // UI용 편집 가능한 리스트도 업데이트
      _editableIngredients
        ..clear()
        ..addAll(updated.ingredients.map((ing) => IngredientEdit(
              name: ing.name,
              quantity: ing.quantity,
              isModified: false,
            )));

      _editableMethods
        ..clear()
        ..addAll(updated.methods.map((m) => MethodEdit(
              describe: m.describe,
              isModified: false,
            )));
    });
  }
  
  Future<void> _initSpeech() async {
    if (!mounted) return;

    try {
      debugPrint('Attempting to initialize speech...');
      _speech = stt.SpeechToText();

      // Wrap the entire initialization in a try-catch to prevent crashes
      final available = await Future(() async {
        try {
          return await _speech!.initialize(
            onStatus: (status) {
              if (!mounted) return;
              debugPrint('Speech status: $status');
              if (status == 'done' || status == 'notListening') {
                setState(() => _isListening = false);
              }
            },
            onError: (error) {
              if (!mounted) return;
              debugPrint('Speech error: ${error.errorMsg}');
              setState(() {
                _isListening = false;
                // Don't disable completely on first error
              });
            },
            debugLogging: false,
          );
        } catch (e) {
          debugPrint('Speech initialize() threw error: $e');
          return false;
        }
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Speech initialization timeout - likely on simulator');
          return false;
        },
      );

      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
        debugPrint('Speech available: $available');
      }
    } catch (e) {
      debugPrint('Speech initialization failed (outer catch): $e');
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
      // Find Korean locale
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

  Future<void> _stopListening() async {
    if (_speech == null) return;

    try {
      await _speech!.stop();
    } catch (e) {
      debugPrint("Speech stop error: $e");
    } finally {
      if (!mounted) return;

      setState(() => _isListening = false);

      final msg = _notesController.text.trim();
      if (msg.isEmpty) return;

      final updated = await sendRecipeEditRequest(
        recipe: _currentRecipe,
        message: msg,
      );

      if (updated != null) {
        _applyRecipeUpdate(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("레시피가 음성 명령에 따라 업데이트되었습니다!")),
        );
      }
    }
  }

  // Future<void> _stopListening() async {
  //   if (_speech == null) return;

  //   try {
  //     await _speech!.stop();
  //   } catch (e) {
  //     debugPrint('Error stopping speech: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isListening = false);
  //     }

  //   // 음성 입력 최종 텍스트 가져오기
  //   final message = _notesController.text.trim();
  //   if (message.isEmpty) return;

  //   // GPT 호출
  //   final updatedRecipe = await sendRecipeEditRequest(
  //     recipe: widget.recipe,
  //     message: message,
  //   );

  //   if (updatedRecipe != null && mounted) {
  //     setState(() {
  //       widget.recipe = updatedRecipe; // recipe 업데이트
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("레시피가 반영되었습니다!")),
  //     );
  //   }

  //   }
  // }

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
    // Split ingredients into two columns
    final halfLength = (_editableIngredients.length / 2).ceil();
    final leftColumn = _editableIngredients.sublist(0, halfLength);
    final rightColumn = _editableIngredients.length > halfLength
        ? _editableIngredients.sublist(halfLength)
        : <IngredientEdit>[];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftColumn.asMap().entries.map((entry) {
              final index = entry.key;
              final ing = entry.value;
              return _buildIngredientEditor(index, ing, key: ValueKey('ingredient_$index'));
            }).toList(),
          ),
        ),
        const SizedBox(width: 4),
        // Right column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rightColumn.asMap().entries.map((entry) {
              final index = halfLength + entry.key;
              final ing = entry.value;
              return _buildIngredientEditor(index, ing, key: ValueKey('ingredient_$index'));
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
      widgets.add(_buildMethodEditor(i, _editableMethods[i], key: ValueKey('method_$i')));

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
    buffer.writeln('레시피: ${widget.recipe.title}\n');

    // 재료 (수정된 것만 또는 전체)
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
    postInput.selectedValue = 'Recipe'; // Default value since review is from speech
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 원본 레시피 이미지
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.recipe.images.originalUrl,
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
          widget.recipe.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // 팁
        if (widget.recipe.tips.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 ${widget.recipe.tips}',
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
        ...widget.recipe.ingredients.map((ing) => Padding(
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
        ...widget.recipe.methods.asMap().entries.map((entry) {
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
        GestureDetector(
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
                        widget.recipe.title,
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
              if (widget.recipe.tips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '💡 ${widget.recipe.tips}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
                ),
              ],

              // 재료 및 조리법 수정 섹션 (확장 시 표시)
              if (_showRecipeDetails) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 재료 수정 섹션 - Recipe book style
                Column(
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Ingredient list in two columns
                      if (_editableIngredients.isNotEmpty)
                        _buildIngredientsGrid(),
                ],
                ),
                const SizedBox(height: 16),

                // 조리법 수정 섹션 - Recipe book style
                Column(
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Methods list with clickable dividers to add steps
                      ..._buildMethodsWithDividers(),
                ],
                ),
              ],
            ],
          ),
        ),
        ),

        const SizedBox(height: 24),

        // Large voice recording button with Siri-like animation
        if (_speechAvailable)
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

        if (_speechAvailable)
          const SizedBox(height: 12),

        // 음성 입력 + 구분점 + 직접 입력하기
        if (_speechAvailable)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 음성 입력 안내 텍스트
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

                  // 직접 입력하기
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _notesController.text = '';
                      });
                    },
                    child: Text(
                      '직접 입력',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        // decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Show text field only if there's content or user is not using voice
        if (hasNotes || !_speechAvailable) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '요리하면서 느낀 점, 맛 평가, 팁 등을 자유롭게 작성해주세요.',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],

        // // Show "직접 입력" button when voice is available but text field is hidden
        // if (_speechAvailable && !hasNotes && !_isListening) ...[
        //   const SizedBox(height: 12),
        //   Center(
        //     child: TextButton.icon(
        //       onPressed: () {
        //         setState(() {
        //           // This will trigger the text field to show
        //           _notesController.text = '';
        //           // hasNotes = true;
        //         });
        //       },
        //       icon: const Icon(Icons.edit, size: 18),
        //       label: const Text('직접 입력하기'),
        //       style: TextButton.styleFrom(
        //         foregroundColor: Colors.grey[400],
        //         side: BorderSide(
        //           color: Colors.grey[600]!,  // 테두리 색
        //           width: 1,                  // 테두리 두께
        //         ),
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(12), // 라운딩 정도
        //         ),
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: 12,
        //           vertical: 8,
        //         ),

        //       ),
        //     ),
        //   ),
        // ],
        const SizedBox(height: 10),

        // 요리 사진 섹션
        Container(
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
                                final currentPage = _imageController.page?.round() ?? 0;
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
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIngredientEditor(int index, IngredientEdit ing, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point
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
          // Ingredient text fields in simple row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ingredient name
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: TextEditingController(text: ing.name),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: ing.isModified ? Colors.amber[100] : Colors.grey[300],
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'ingredient',
                      hintStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                      filled: false,
                    ),
                    onChanged: (value) {
                      ing.name = value;
                      ing.isModified = true;
                      setState(() {});
                    },
                  ),
                ),
                // Vertical bar separator
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
                // Amount
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: ing.quantity),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey[400],
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'amount',
                      hintStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                      filled: false,
                    ),
                    onChanged: (value) {
                      ing.quantity = value;
                      ing.isModified = true;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          // Remove button - minimal
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              onTap: () => _removeIngredient(index),
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

  Widget _buildMethodEditor(int index, MethodEdit method, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number in text
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              '${index + 1}.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.6,
                color: method.isModified ? Colors.orange[400] : Colors.grey[400],
              ),
            ),
          ),
          // Method description as flowing text
          Expanded(
            child: TextField(
              controller: TextEditingController(text: method.describe),
              maxLines: null,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: method.isModified ? Colors.orange[100] : Colors.grey[300],
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 4),
                hintText: 'Describe this step of the recipe...',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                filled: false,
              ),
              onChanged: (value) {
                method.describe = value;
                method.isModified = true;
                setState(() {});
              },
            ),
          ),
          // Remove button - minimal
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: InkWell(
              onTap: () => _removeMethod(index),
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

// 편집 가능한 재료 모델
class IngredientEdit {
  String name;
  String quantity;
  bool isModified;

  IngredientEdit({
    required this.name,
    required this.quantity,
    required this.isModified,
  });
}

// 편집 가능한 조리법 모델
class MethodEdit {
  String describe;
  bool isModified;

  MethodEdit({
    required this.describe,
    required this.isModified,
  });
}
