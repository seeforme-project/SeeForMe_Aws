import 'dart:ui' as ui; // <--- ADDED 'as ui'
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectorPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final InputImageRotation rotation;
  final Size widgetSize;

  ObjectDetectorPainter(
      this.objects,
      this.imageSize,
      this.rotation,
      this.widgetSize,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;

    final Paint background = Paint()
      ..color = const Color(0x99000000);

    for (final DetectedObject object in objects) {
      final rect = _transformRect(
        object.boundingBox,
        imageSize,
        widgetSize,
        rotation,
      );

      // Draw Rect
      canvas.drawRect(rect, paint);

      // Draw Label
      if (object.labels.isNotEmpty) {
        final label = object.labels.first;
        final text = "${label.text} ${(label.confidence * 100).toStringAsFixed(0)}%";

        final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            textDirection: TextDirection.ltr,
          ),
        );

        // ui.TextStyle is now valid because of the import alias
        builder.pushStyle(ui.TextStyle(color: Colors.white, background: background));
        builder.addText(text);
        builder.pop();

        canvas.drawParagraph(
          builder.build()..layout(ui.ParagraphConstraints(width: rect.width)),
          Offset(rect.left, rect.top - 20),
        );
      }
    }
  }

  Rect _transformRect(Rect boundingBox, Size imageSize, Size widgetSize, InputImageRotation rotation) {
    // Android is typically portrait (90 deg), so we swap width/height logic
    double scaleX = widgetSize.width / imageSize.height;
    double scaleY = widgetSize.height / imageSize.width;

    double top = boundingBox.top * scaleY;
    double left = boundingBox.left * scaleX;
    double right = boundingBox.right * scaleX;
    double bottom = boundingBox.bottom * scaleY;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool shouldRepaint(covariant ObjectDetectorPainter oldDelegate) {
    return oldDelegate.objects != objects;
  }
}