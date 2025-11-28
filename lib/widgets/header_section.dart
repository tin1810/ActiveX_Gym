import 'package:flutter/material.dart';
import '../services/auth.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile Picture
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 30,
          ),
        ),
        const SizedBox(width: 15),
        // Greeting and Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                MockAuthService.instance.currentUser.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Notification and Menu Icons
        Row(
          children: [
            Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: Colors.grey[600],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Icon(
              Icons.more_horiz,
              size: 24,
              color: Colors.grey[600],
            ),
          ],
        ),
      
      ],
    );
  }
}
