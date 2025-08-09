// DateTimePickerDialog.dart
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

Future<DateTime?> showCustomDateTimeDialog({
  required BuildContext context,
  required DateTime initial,
  VoidCallback? onCancelToFinalCheck,
}) async {
  DateTime tempPicked = initial;
  int hour = initial.hour;
  int minute = (initial.minute ~/ 5) * 5;

  return showDialog<DateTime?>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (inner, setInner) {
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
                        style: TextButton.styleFrom(foregroundColor: Colors.black),
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: tempPicked,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                      onDateChanged: (d) {
                        setInner(() {
                          tempPicked = DateTime(d.year, d.month, d.day, hour, minute);
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
                        items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i시'))),
                        onChanged: (v) {
                          if (v == null) return;
                          setInner(() {
                            hour = v;
                            tempPicked = DateTime(tempPicked.year, tempPicked.month, tempPicked.day, hour, minute);
                          });
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 50, width: 100,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      DropdownButton2<int>(
                        value: minute,
                        items: List.generate(12, (i) => DropdownMenuItem(value: i * 5, child: Text('${i * 5}분'))),
                        onChanged: (v) {
                          if (v == null) return;
                          setInner(() {
                            minute = v;
                            tempPicked = DateTime(tempPicked.year, tempPicked.month, tempPicked.day, hour, minute);
                          });
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          height: 50, width: 100,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, null);
                          onCancelToFinalCheck?.call();
                        },
                        child: const Text('취소', style: TextStyle(color: Colors.black, fontSize: 14)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, tempPicked),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: const Text('저장', style: TextStyle(color: Colors.white, fontSize: 14)),
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
