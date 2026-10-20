import 'dart:math' as math;

({double width, double height}) fitImageWithinBounds({
  required double imageWidth,
  required double imageHeight,
  required double maxWidth,
  required double maxHeight,
}) {
  if (imageWidth <= 0 || imageHeight <= 0 || maxWidth <= 0 || maxHeight <= 0) {
    return (width: maxWidth, height: maxHeight);
  }

  final double scale = math.min(maxWidth / imageWidth, maxHeight / imageHeight);
  return (width: imageWidth * scale, height: imageHeight * scale);
}
