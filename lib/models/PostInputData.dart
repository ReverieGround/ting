
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostInputData {
  List<File> imageFiles; // File? -> List<File>로 변경
  String selectedValue="";
  String selectedCategory="";
  String capturedDate = DateFormat('yyyy. MM. dd HH:mm').format(DateTime.now());
  bool recommendRecipe = false;
  String mealKitLink="";
  String restaurantLink="";
  String deliveryLink="";
  TextEditingController textController = TextEditingController();
  String get content => textController.text;
  PostInputData({required this.imageFiles}); // 생성자도 변경
}
