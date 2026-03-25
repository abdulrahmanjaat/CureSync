// ignore_for_file: avoid_print
// Run with: dart run tool/generate_icon.dart
// Generates a 1024x1024 launcher icon matching the CureSyncLogo

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() {
  const size = 1024;
  final pixels = Uint8List(size * size * 4);

  // Colors
  const double tealR = 13, tealG = 148, tealB = 136;       // #0D9488
  const double tealLR = 20, tealLG = 184, tealLB = 166;     // #14B8A6
  const double coralR = 255, coralG = 107, coralB = 107;     // #FF6B6B
  const double whR = 255, whG = 255, whB = 255;

  final cx = size / 2.0, cy = size / 2.0;
  final s = size.toDouble();

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final i = (y * size + x) * 4;
      final dx = x - cx, dy = y - cy;

      // 1. Rounded square background (#0D9488)
      final cornerR = s * 0.22;
      final inset = s * 0.02;
      final inRoundedSquare = _inRoundedRect(
        x.toDouble(), y.toDouble(),
        inset, inset, s - inset, s - inset,
        cornerR,
      );

      if (!inRoundedSquare) {
        pixels[i] = 0; pixels[i+1] = 0; pixels[i+2] = 0; pixels[i+3] = 0;
        continue;
      }

      // Gradient from teal to tealLight (top-left to bottom-right)
      final t = ((x + y) / (2.0 * size)).clamp(0.0, 1.0);
      var r = _lerp(tealR, tealLR, t);
      var g = _lerp(tealG, tealLG, t);
      var b = _lerp(tealB, tealLB, t);

      // 2. Shield shape (heart-shield) — brighter center
      final shieldTop = cy - s * 0.30;
      final shieldBottom = cy + s * 0.32;
      if (_inShield(x.toDouble(), y.toDouble(), cx, cy, s, shieldTop, shieldBottom)) {
        // Slightly lighter fill for the shield
        final st = ((x + y) / (2.0 * size)).clamp(0.0, 1.0);
        r = _lerp(tealR + 15, tealLR + 10, st);
        g = _lerp(tealG + 15, tealLG + 10, st);
        b = _lerp(tealB + 15, tealLB + 10, st);

        // 3. White cross
        final crossW = s * 0.075;
        final crossH = s * 0.22;
        final inVert = (dx).abs() < crossW / 2 && (dy).abs() < crossH / 2;
        final inHorz = (dy).abs() < crossW / 2 && (dx).abs() < crossH / 2;

        if (inVert || inHorz) {
          r = whR; g = whG; b = whB;
        }
      }

      // 4. Coral orbit ring
      final tilt = -pi / 7;
      final rdx = dx * cos(tilt) + dy * sin(tilt);
      final rdy = -dx * sin(tilt) + dy * cos(tilt);
      final orbitR = s * 0.38;
      final ringDist = sqrt(rdx * rdx + rdy * rdy);
      final ringWidth = s * 0.03;

      if ((ringDist - orbitR).abs() < ringWidth) {
        final angle = atan2(rdy, rdx);
        final startA = -pi * 0.15;
        final endA = startA + pi * 1.35;
        final normAngle = _normalizeAngle(angle);
        final normStart = _normalizeAngle(startA);
        final normEnd = _normalizeAngle(endA);

        bool inArc;
        if (normStart < normEnd) {
          inArc = normAngle >= normStart && normAngle <= normEnd;
        } else {
          inArc = normAngle >= normStart || normAngle <= normEnd;
        }

        if (inArc) {
          r = coralR; g = coralG; b = coralB;
        }
      }

      // 5. Coral dots at arc endpoints
      final dotR = s * 0.04;
      final endAngle = -pi * 0.15 + pi * 1.35;
      final dot1x = orbitR * cos(endAngle);
      final dot1y = orbitR * sin(endAngle);
      // Rotate back
      final d1x = dot1x * cos(-tilt) + dot1y * sin(-tilt);
      final d1y = -dot1x * sin(-tilt) + dot1y * cos(-tilt);
      if (sqrt(pow(dx - d1x, 2) + pow(dy - d1y, 2)) < dotR) {
        r = coralR; g = coralG; b = coralB;
      }

      final startAngle = -pi * 0.15;
      final dot2x = orbitR * cos(startAngle);
      final dot2y = orbitR * sin(startAngle);
      final d2x = dot2x * cos(-tilt) + dot2y * sin(-tilt);
      final d2y = -dot2x * sin(-tilt) + dot2y * cos(-tilt);
      if (sqrt(pow(dx - d2x, 2) + pow(dy - d2y, 2)) < dotR * 0.65) {
        r = coralR; g = coralG; b = coralB;
      }

      pixels[i] = r.round().clamp(0, 255);
      pixels[i+1] = g.round().clamp(0, 255);
      pixels[i+2] = b.round().clamp(0, 255);
      pixels[i+3] = 255;
    }
  }

  final bmp = _encodeBmp(size, size, pixels);
  File('res/images/launcher_icon.bmp').writeAsBytesSync(bmp);
  print('Generated res/images/launcher_icon.bmp (${bmp.length} bytes)');
  print('Now run: dart run flutter_launcher_icons');
}

bool _inRoundedRect(double x, double y, double l, double t, double r, double b, double radius) {
  if (x < l || x > r || y < t || y > b) return false;
  // Check corners
  if (x < l + radius && y < t + radius) {
    return pow(x - (l + radius), 2) + pow(y - (t + radius), 2) <= radius * radius;
  }
  if (x > r - radius && y < t + radius) {
    return pow(x - (r - radius), 2) + pow(y - (t + radius), 2) <= radius * radius;
  }
  if (x < l + radius && y > b - radius) {
    return pow(x - (l + radius), 2) + pow(y - (b - radius), 2) <= radius * radius;
  }
  if (x > r - radius && y > b - radius) {
    return pow(x - (r - radius), 2) + pow(y - (b - radius), 2) <= radius * radius;
  }
  return true;
}

bool _inShield(double x, double y, double cx, double cy, double s, double top, double bottom) {
  // Simplified shield — ellipse that narrows to bottom point
  final normY = (y - top) / (bottom - top); // 0 at top, 1 at bottom
  if (normY < 0 || normY > 1) return false;

  // Width narrows as we go down
  double halfW;
  if (normY < 0.15) {
    // Top: heart lobes — wider
    halfW = s * 0.24 * (0.5 + normY * 3.3);
  } else if (normY < 0.6) {
    halfW = s * 0.28;
  } else {
    // Taper to point
    halfW = s * 0.28 * (1.0 - pow((normY - 0.6) / 0.4, 1.5));
  }

  return (x - cx).abs() < halfW;
}

double _normalizeAngle(double a) {
  var n = a % (2 * pi);
  if (n < 0) n += 2 * pi;
  return n;
}

double _lerp(num a, num b, double t) => a + (b - a) * t;

Uint8List _encodeBmp(int w, int h, Uint8List rgba) {
  final rowSize = w * 4;
  final imageSize = rowSize * h;
  final fileSize = 54 + imageSize;
  final bmp = ByteData(fileSize);

  bmp.setUint8(0, 0x42);
  bmp.setUint8(1, 0x4D);
  bmp.setUint32(2, fileSize, Endian.little);
  bmp.setUint32(10, 54, Endian.little);
  bmp.setUint32(14, 40, Endian.little);
  bmp.setInt32(18, w, Endian.little);
  bmp.setInt32(22, -h, Endian.little);
  bmp.setUint16(26, 1, Endian.little);
  bmp.setUint16(28, 32, Endian.little);
  bmp.setUint32(30, 0, Endian.little);
  bmp.setUint32(34, imageSize, Endian.little);

  for (int i = 0; i < w * h; i++) {
    final si = i * 4;
    final di = 54 + i * 4;
    bmp.setUint8(di, rgba[si + 2]);
    bmp.setUint8(di + 1, rgba[si + 1]);
    bmp.setUint8(di + 2, rgba[si]);
    bmp.setUint8(di + 3, rgba[si + 3]);
  }

  return bmp.buffer.asUint8List();
}
