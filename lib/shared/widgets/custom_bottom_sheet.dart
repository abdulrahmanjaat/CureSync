import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CustomBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    double borderRadius = 24,
    double initialChildSize = 0.5,
    double maxChildSize = 0.9,
    double minChildSize = 0.25,
    bool useDraggable = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
          ),
          child: useDraggable
              ? DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: initialChildSize,
                  maxChildSize: maxChildSize,
                  minChildSize: minChildSize,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: child,
                    );
                  },
                )
              : child,
        );
      },
    );
  }
}
