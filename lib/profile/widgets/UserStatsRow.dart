// lib/widgets/user_stats_row.dart
import 'package:flutter/material.dart';

class UserStatsRow extends StatelessWidget {
  final int yumCount;
  final int recipeCount;
  final int followerCount;
  final int followingCount;

  const UserStatsRow({
    super.key,
    required this.yumCount,
    required this.recipeCount,
    required this.followerCount,
    required this.followingCount,
  });

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(context, 'Yum', yumCount),
          _buildStatItem(context, 'Recipe', recipeCount),
          _buildStatItem(context, 'Follower', followerCount, addComma: true),
          _buildStatItem(context, 'Following', followingCount, addComma: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int count, {bool addComma = false}) {
    
    String displayCount = addComma ? count.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    ) : count.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          displayCount,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}