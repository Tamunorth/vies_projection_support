import 'package:flutter/material.dart';
import 'package:vies_projection_support/core/analytics.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    super.key,
    this.onTap,
    this.color = Colors.blue,
    required this.title,
  });

  final VoidCallback? onTap;
  final String title;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                Analytics.instance.trackEventWithProperties(
                  "button_tapped",
                  {
                    'button_title': title,
                  },
                );
                onTap?.call();
              },
        child: Container(
          height: 55,
          width: 250,
          decoration: BoxDecoration(
            color: onTap == null ? Colors.grey : color,
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
