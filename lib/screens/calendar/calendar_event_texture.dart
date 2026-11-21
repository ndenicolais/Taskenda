// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart';

/// Light pattern drawn behind the content of a plain event (see
/// `CalendarItemStyle.texture`): it tells all-day and timed events apart
/// even when they share a color.
enum EventTexture {
  /// Diagonal stripes: all-day events.
  stripes,

  /// Staggered dots: timed events.
  dots,
}

/// Paints [texture] in [color] (already faded: the pattern stays behind the
/// text).
class EventTexturePainter extends CustomPainter {
  const EventTexturePainter({required this.texture, required this.color});

  final EventTexture texture;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..isAntiAlias = true;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (texture) {
      case EventTexture.stripes:
        const gap = 9.0;
        paint
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        // Lines going up to the right, covering the whole box.
        for (var x = -size.height; x < size.width; x += gap) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            paint,
          );
        }
      case EventTexture.dots:
        const gap = 8.0;
        paint.style = PaintingStyle.fill;
        var row = 0;
        for (var y = gap / 2; y < size.height; y += gap, row++) {
          final shift = row.isOdd ? gap / 2 : 0.0;
          for (var x = gap / 2 + shift; x < size.width; x += gap) {
            canvas.drawCircle(Offset(x, y), 0.9, paint);
          }
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(EventTexturePainter old) =>
      old.texture != texture || old.color != color;
}
