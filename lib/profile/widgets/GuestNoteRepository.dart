import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/StickyNoteModel.dart';
import 'NoteColorPalette.dart';

class GuestBookRepository {
  final _rand = Random();

  Future<List<StickyNoteModel>> fetchInitial() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.generate(12, (i) {
      final c = NoteColorPalette.pastel[_rand.nextInt(NoteColorPalette.pastel.length)];
      final rot = [-4, -2, 0, 2, 4][_rand.nextInt(5)].toDouble();
      return StickyNoteModel(
        id: '$i',
        authorId: "autoId",
        authorName: 'Visitor ${i + 1}',
        authorAvatarUrl: '',
        createdAt: DateTime.now().subtract(Duration(minutes: i * 7)),
        text: i % 4 == 0 ? '항상 응원해요! \n다음에도 올게요.' : '좋은 하루 보내세요 :)',
        color: c,
        pinned: i % 5 == 0,
      );
    });
  }
}
