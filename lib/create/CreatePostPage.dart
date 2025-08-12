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

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  final List<PostInputData> postInputs = List.generate(3, (_) => PostInputData(imageFiles: []));

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
      onCancelToFinalCheck: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmPage(postInputs: postInputs)));
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(picked);
      });
    }
  }

  Future<void> _pickImages(int index) async {
    final flow = ImagePickerFlow();
    final result = await flow.pickAndEdit(context);
    if (result == null) return;

    setState(() => postInputs[index].imageFiles = result.files);

    if (result.takenAt != null) {
      setState(() => capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(result.takenAt!));
    } else if (result.files.isNotEmpty) {
      final exifDate = await ExifHelper.extractTakenAt(result.files.first);
      if (exifDate != null) {
        setState(() => capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(exifDate));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = postInputs[_currentIndex];

    return Scaffold(
      appBar: AppHeader(
        backgroundColor: Colors.white,
        centerTitle: true,
        titleWidget: HeaderDateTitle(
          capturedDate: capturedDate,
          onTap: _openDateTimePicker,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) {
                  final input = postInputs[index];
                  return ImageCarousel(
                    pageController: _pageController,
                    images: input.imageFiles,
                    onTap: () => _pickImages(index),
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
                  CategoryChips(
                    categories: categories,
                    selected: currentInput.selectedCategory,
                    onSelect: (v) => setState(() {
                      currentInput.selectedCategory =
                          currentInput.selectedCategory == v ? "" : v;
                    }),
                  ),
                  const SizedBox(height: 8),
                  ReviewChips(
                    items: reviewValues,
                    selected: currentInput.selectedValue,
                    onSelect: (v) => setState(() => currentInput.selectedValue = v),
                  ),
                  const SizedBox(height: 16),
                  PostTextField(controller: currentInput.textController),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            if (currentInput.selectedCategory.contains('요리'))
              RecommendRecipeToggle(
                value: currentInput.recommendRecipe,
                onChanged: (v) => setState(() => currentInput.recommendRecipe = v),
              ),
            if (currentInput.selectedCategory.contains('밀키트'))
              SectionMealKit(
                value: currentInput.mealKitLink,
                onSubmitted: (v) => setState(() => currentInput.mealKitLink = v),
              ),
            if (currentInput.selectedCategory.contains('식당'))
              SectionRestaurant(
                value: currentInput.restaurantLink,
                onSubmitted: (v) => setState(() => currentInput.restaurantLink = v),
              ),
            if (currentInput.selectedCategory.contains('배달'))
              SectionDelivery(
                value: currentInput.deliveryLink,
                onSubmitted: (v) => setState(() => currentInput.deliveryLink = v),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNextButton(
        isLoading: isUploading,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmPage(postInputs: postInputs)));
        },
      ),
    );
  }
}
