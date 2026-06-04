import 'package:flutter/material.dart';

/// Centered square crop guide for the fixed-mount overhead camera.
class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth * 0.55
              : constraints.maxHeight * 0.55;
          return Center(
            child: Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
