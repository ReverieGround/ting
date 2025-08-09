import 'package:flutter/material.dart';

class PickSection extends StatelessWidget {
  final int numItems;

  const PickSection({super.key, this.numItems = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 15, 20, 10),
          child: Text(
            "Pick",
            style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w400),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(
              left: 24,
              right: numItems == 1 ? 20 : 0,
            ),
            itemCount: numItems,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              return Align(
                alignment: Alignment.center,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(30, 60, 60, 60),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: index == 3 ? const Icon(Icons.coffee, size: 40) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
