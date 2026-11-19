import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const inputPath = 'assets/images/logo_raw.jpg';
  const outputPath = 'assets/images/logo_icon.png';

  final bytes = File(inputPath).readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('❌ تعذّر قراءة الصورة من $inputPath');
    return;
  }

  // 1. تحديد حدود الرسمة الفعلية يدوياً لتجاوز شوائب ضغط JPG
  int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      // اعتبار أي بكسل ليس أبيضاً ناصعاً جزءاً من اللوغو
      if (p.r < 240 || p.g < 240 || p.b < 240) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  final cropped = img.copyCrop(
    image,
    x: minX,
    y: minY,
    width: (maxX - minX) + 1,
    height: (maxY - minY) + 1,
  );

  // 2. إنشاء لوحة مربعة 1024x1024 بخلفية بيضاء نقية
  const canvasSize = 1024;
  final canvas = img.Image(width: canvasSize, height: canvasSize);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

  // 3. تصغير اللوغو ليحتل 58% من الارتفاع مع الحفاظ التام على التناسب (بدون تمطط أفقي)
  final targetHeight = (canvasSize * 0.58).round();
  final resized = img.copyResize(
    cropped,
    height: targetHeight,
    interpolation: img.Interpolation.cubic,
  );

  // 4. توسيط اللوغو في منتصف الأيقونة تماماً
  final dstX = (canvasSize - resized.width) ~/ 2;
  final dstY = (canvasSize - resized.height) ~/ 2;
  img.compositeImage(canvas, resized, dstX: dstX, dstY: dstY);

  File(outputPath).writeAsBytesSync(img.encodePng(canvas));
  print('✅ تم إنشاء الأيقونة المتناسقة (${resized.width}x${resized.height}) داخل 1024x1024');
}