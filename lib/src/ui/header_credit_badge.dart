import 'package:flutter/material.dart';

class HeaderCreditBadge extends StatelessWidget {
  const HeaderCreditBadge({super.key, required this.credits});

  final int? credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EBDD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        credits == null ? 'Credits' : '$credits left',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF5C4635),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
