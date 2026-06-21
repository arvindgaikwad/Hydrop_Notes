// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/canvas_objects.dart';
import '../widgets/canvas_background_pattern.dart';
import 'dart:convert';

class ExportController {
  static Rect _calculateCanvasBounds(List<CanvasLayer> layers) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    bool hasContent = false;

    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        for (final p in stroke.points) {
          if (p.point.dx < minX) minX = p.point.dx;
          if (p.point.dy < minY) minY = p.point.dy;
          if (p.point.dx > maxX) maxX = p.point.dx;
          if (p.point.dy > maxY) maxY = p.point.dy;
          hasContent = true;
        }
      }

      for (final node in layer.textNodes) {
        if (node.position.dx < minX) minX = node.position.dx;
        if (node.position.dy < minY) minY = node.position.dy;
        if (node.position.dx + node.width > maxX) maxX = node.position.dx + node.width;
        if (node.position.dy + node.height > maxY) maxY = node.position.dy + node.height;
        hasContent = true;
      }

      for (final node in layer.imageNodes) {
        if (node.position.dx < minX) minX = node.position.dx;
        if (node.position.dy < minY) minY = node.position.dy;
        if (node.position.dx + node.width > maxX) maxX = node.position.dx + node.width;
        if (node.position.dy + node.height > maxY) maxY = node.position.dy + node.height;
        hasContent = true;
      }

      for (final node in layer.documentNodes) {
        if (node.position.dx < minX) minX = node.position.dx;
        if (node.position.dy < minY) minY = node.position.dy;
        if (node.position.dx + node.width > maxX) maxX = node.position.dx + node.width;
        if (node.position.dy + node.height > maxY) maxY = node.position.dy + node.height;
        hasContent = true;
      }
    }

    if (!hasContent) {
      return const Rect.fromLTWH(0, 0, 1240, 1754);
    }

    return Rect.fromLTRB(minX - 50, minY - 50, maxX + 50, maxY + 50);
  }

  static Future<void> _saveOrShare(Uint8List bytes, String fileName, String extension) async {
    try {
      if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Export',
          fileName: '$fileName.$extension',
        );
        if (outputFile != null) {
          await File(outputFile).writeAsBytes(bytes);
        }
      } else {
        await Printing.sharePdf(bytes: bytes, filename: '$fileName.$extension');
      }
    } catch (_) {
      await Printing.sharePdf(bytes: bytes, filename: '$fileName.$extension');
    }
  }

  static Future<void> exportToPdf(
    List<CanvasLayer> layers, {
    String canvasType = 'infinite',
    Rect? cropRect,
    String fileName = 'horizon_export',
    bool includeGrid = false,
    bool transparentBackground = false,
    CanvasBackgroundVariant backgroundVariant = CanvasBackgroundVariant.none,
  }) async {
    final bounds = _calculateCanvasBounds(layers);
    final pdf = pw.Document();

    final pageFormat = cropRect != null
        ? PdfPageFormat(cropRect.width, cropRect.height)
        : (canvasType == 'a4'
            ? PdfPageFormat.a4
            : PdfPageFormat(bounds.width, bounds.height));

    final pdfImages = <String, pw.MemoryImage>{};
    final rasterizedStrokes = <String, pw.MemoryImage>{};

    for (final layer in layers) {
      if (!layer.isVisible) continue;
      
      for (final node in layer.imageNodes) {
        if (node.filePath.isNotEmpty && !pdfImages.containsKey(node.id)) {
          try {
            final file = File(node.filePath);
            if (file.existsSync()) {
              pdfImages[node.id] = pw.MemoryImage(await file.readAsBytes());
            }
          } catch (e) {
            debugPrint("Failed to load PDF image: $e");
          }
        }
      }

      final hasEraser = layer.strokes.any((s) => s.isPixelEraser);
      if (hasEraser) {
        final boundsW = cropRect?.width ?? bounds.width;
        final boundsH = cropRect?.height ?? bounds.height;
        if (boundsW > 0 && boundsH > 0) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          
          final scale = 3.0;
          canvas.scale(scale, scale);
          
          final offsetDx = cropRect != null ? -cropRect.left : -bounds.left;
          final offsetDy = cropRect != null ? -cropRect.top : -bounds.top;
          canvas.translate(offsetDx, offsetDy);

          canvas.saveLayer(null, Paint());
          for (var stroke in layer.strokes) {
            if (stroke.points.isEmpty) continue;

            final paint = Paint()
              ..color = stroke.color
              ..style = (!stroke.isInkPen && !stroke.isPixelEraser) ? PaintingStyle.stroke : PaintingStyle.fill
              ..strokeWidth = stroke.baseWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round;

            if (stroke.isPixelEraser) {
              paint.blendMode = BlendMode.clear;
              paint.style = PaintingStyle.stroke;
              paint.strokeWidth = stroke.baseWidth;
            } else if (stroke.isTape) {
              paint.color = stroke.color.withValues(alpha: stroke.isTapeRevealed ? 0.2 : 0.95);
            }
            canvas.drawPath(stroke.path, paint);
          }
          canvas.restore();
          
          final picture = recorder.endRecording();
          final img = await picture.toImage((boundsW * scale).toInt(), (boundsH * scale).toInt());
          final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            rasterizedStrokes[layer.id] = pw.MemoryImage(byteData.buffer.asUint8List());
          }
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          final paintSize = cropRect != null
              ? PdfPoint(cropRect.width, cropRect.height)
              : PdfPoint(bounds.width, bounds.height);
          final offset = cropRect != null
              ? Offset(-cropRect.left, -cropRect.top)
              : Offset(-bounds.left, -bounds.top);

          final children = <pw.Widget>[];

          if (!transparentBackground) {
            children.add(
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Container(
                  width: paintSize.x,
                  height: paintSize.y,
                  color: PdfColors.white,
                )
              )
            );
          }

          for (final layer in layers) {
            if (!layer.isVisible) continue;
            
            for (final node in layer.imageNodes) {
              if (pdfImages.containsKey(node.id)) {
                 children.add(
                   pw.Positioned(
                     left: node.position.dx + offset.dx,
                     top: node.position.dy + offset.dy,
                     child: pw.Transform(
                       transform: Matrix4.identity()
                         ..translate(node.width/2, node.height/2)
                         ..rotateZ(node.rotation)
                         ..scale(node.scale)
                         ..translate(-node.width/2, -node.height/2),
                       alignment: pw.Alignment.center,
                       child: pw.Container(
                         width: node.width,
                         height: node.height,
                         child: pw.Image(pdfImages[node.id]!, fit: pw.BoxFit.fill),
                       )
                     ),
                   )
                 );
              }
            }

            if (rasterizedStrokes.containsKey(layer.id)) {
                children.add(
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: pw.Container(
                      width: paintSize.x,
                      height: paintSize.y,
                      child: pw.Image(rasterizedStrokes[layer.id]!, fit: pw.BoxFit.fill),
                    )
                  )
                );
            } else {
                children.add(
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: pw.CustomPaint(
                      size: paintSize,
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        _paintPdfCanvas(canvas, size, [layer], offset: offset);
                      },
                    )
                  )
                );
            }
          }

          return pw.FullPage(
            ignoreMargins: true,
            child: pw.ClipRect(
              child: pw.Stack(
                children: children,
              ),
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await _saveOrShare(bytes, fileName, 'pdf');
  }

  static Future<void> exportToSvg(
    BuildContext context,
    List<CanvasLayer> layers, {
    Rect? cropRect,
    String fileName = 'horizon_export',
    bool includeGrid = false,
    bool transparentBackground = false,
    CanvasBackgroundVariant backgroundVariant = CanvasBackgroundVariant.none,
  }) async {
    final bounds = _calculateCanvasBounds(layers);
    final format = cropRect ?? bounds;

    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    sb.writeln('<svg width="${format.width}" height="${format.height}" viewBox="0 0 ${format.width} ${format.height}" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
    
    if (!transparentBackground) {
      sb.writeln('  <rect width="100%" height="100%" fill="white" />');
    }

    final double offsetX = (cropRect != null) ? -cropRect.left : -bounds.left;
    final double offsetY = (cropRect != null) ? -cropRect.top : -bounds.top;

    if (includeGrid && backgroundVariant == CanvasBackgroundVariant.grid) {
       sb.writeln('''
  <defs>
    <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse" patternTransform="translate($offsetX, $offsetY)">
      <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#252525" stroke-opacity="0.1" stroke-width="1"/>
    </pattern>
  </defs>
  <rect width="100%" height="100%" fill="url(#grid)" />
       ''');
    } else if (includeGrid && backgroundVariant == CanvasBackgroundVariant.dots) {
       sb.writeln('''
  <defs>
    <pattern id="dots" width="40" height="40" patternUnits="userSpaceOnUse" patternTransform="translate($offsetX, $offsetY)">
      <circle cx="2" cy="2" r="2" fill="#252525" fill-opacity="0.2"/>
    </pattern>
  </defs>
  <rect width="100%" height="100%" fill="url(#dots)" />
       ''');
    }

    sb.writeln('<g transform="translate(${-format.left}, ${-format.top})">');

    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Image Nodes
      for (final imageNode in layer.imageNodes) {
        if (imageNode.filePath.isEmpty) continue;
        try {
          final file = File(imageNode.filePath);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            final base64String = base64Encode(bytes);

            // Determine mime type from file extension
            String mimeType = 'image/png';
            if (imageNode.filePath.toLowerCase().endsWith('.jpg') || imageNode.filePath.toLowerCase().endsWith('.jpeg')) {
              mimeType = 'image/jpeg';
            } else if (imageNode.filePath.toLowerCase().endsWith('.webp')) {
              mimeType = 'image/webp';
            }

            final dataUri = 'data:$mimeType;base64,$base64String';

            final cx = imageNode.position.dx + imageNode.width / 2;
            final cy = imageNode.position.dy + imageNode.height / 2;

            // SVG transform takes degrees for rotation
            final rotationDeg = imageNode.rotation * 180 / 3.141592653589793;

            sb.write('<g transform="translate($cx $cy) rotate($rotationDeg) scale(${imageNode.scale}) translate(${-imageNode.width/2} ${-imageNode.height/2})">\n');
            sb.write('  <image width="${imageNode.width}" height="${imageNode.height}" preserveAspectRatio="none" xlink:href="$dataUri"/>\n');
            sb.write('</g>\n');
          }
        } catch (e) {
          debugPrint("Failed to encode SVG image node: $e");
        }
      }

      // Text Nodes
      for (final textNode in layer.textNodes) {
        if (textNode.text.isEmpty) continue;

        final color = textNode.color;
        final hexColor = '#${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
        final opacity = color.a;

        String textAnchor = "start";
        double xOffset = 0;
        if (textNode.alignmentIndex == 1) {
          textAnchor = "middle";
          xOffset = textNode.width / 2;
        } else if (textNode.alignmentIndex == 2) {
          textAnchor = "end";
          xOffset = textNode.width;
        }

        String fontWeight = textNode.isBold ? "bold" : "normal";
        String fontStyle = textNode.isItalic ? "italic" : "normal";
        String textDecoration = textNode.isUnderline ? "underline" : "none";

        final cx = textNode.position.dx + textNode.width / 2;
        final cy = textNode.position.dy + textNode.height / 2;
        final rotationDeg = textNode.rotation * 180 / 3.141592653589793;

        // Escape XML entities
        final escapedText = textNode.text
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&apos;');

        sb.write('<g transform="translate($cx $cy) rotate($rotationDeg) scale(${textNode.scale}) translate(${-textNode.width/2} ${-textNode.height/2})">\n');

        // Very basic multi-line handling by splitting on \n
        final lines = escapedText.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final dy = (i + 1) * textNode.fontSize * 1.2; // roughly line-height
          sb.write('  <text x="$xOffset" y="$dy" font-family="Delicious Handrawn, sans-serif" font-size="${textNode.fontSize}" font-weight="$fontWeight" font-style="$fontStyle" text-decoration="$textDecoration" fill="$hexColor" fill-opacity="$opacity" text-anchor="$textAnchor">${lines[i]}</text>\n');
        }

        sb.write('</g>\n');
      }

      // Document Nodes
      for (final docNode in layer.documentNodes) {
        final cx = docNode.position.dx + docNode.width / 2;
        final cy = docNode.position.dy + docNode.height / 2;
        final rotationDeg = docNode.rotation * 180 / 3.141592653589793;

        sb.write('<g transform="translate($cx $cy) rotate($rotationDeg) scale(${docNode.scale}) translate(${-docNode.width/2} ${-docNode.height/2})">\n');

        // Draw the document node background / box
        sb.write('  <rect x="0" y="0" width="${docNode.width}" height="${docNode.height}" rx="12" ry="12" fill="#FFFFFF" stroke="#E0E0E0" stroke-width="1"/>\n');

        if (docNode.text.isNotEmpty) {
          final escapedText = docNode.text
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('"', '&quot;')
              .replaceAll("'", '&apos;');

          final lines = escapedText.split('\n');
          for (int i = 0; i < lines.length; i++) {
             // 16px font, start at y=12+16=28
             final dy = 28 + (i * 16 * 1.5);
             sb.write('  <text x="16" y="$dy" font-family="Inter, sans-serif" font-size="16" fill="#000000">${lines[i]}</text>\n');
          }
        }

        sb.write('</g>\n');
      }

      // Strokes (Pens, Highlights)
      final hasEraser = layer.strokes.any((s) => s.isPixelEraser);
      
      if (hasEraser) {
        sb.writeln('  <defs>');
        sb.writeln('    <mask id="eraser_mask_${layer.id}">');
        sb.writeln('      <rect width="100%" height="100%" fill="white" />');
        
        for (final stroke in layer.strokes) {
          if (!stroke.isPixelEraser) continue;
          if (stroke.points.length < 2) continue;
          
          final pathPoints = stroke.points;
          sb.write('      <path d="');
          sb.write('M ${pathPoints.first.point.dx} ${pathPoints.first.point.dy} ');
          if (pathPoints.length == 2) {
            sb.write('L ${pathPoints[1].point.dx} ${pathPoints[1].point.dy} ');
          } else {
            for (int i = 1; i < pathPoints.length - 1; i++) {
              final p0 = pathPoints[i].point;
              final p1 = pathPoints[i + 1].point;
              final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
              sb.write('Q ${p0.dx} ${p0.dy} ${mid.dx} ${mid.dy} ');
            }
            sb.write('L ${pathPoints.last.point.dx} ${pathPoints.last.point.dy} ');
          }
          sb.write('" fill="none" stroke="black" stroke-width="${stroke.baseWidth}" stroke-linecap="round" stroke-linejoin="round" />\n');
        }
        
        sb.writeln('    </mask>');
        sb.writeln('  </defs>');
        sb.writeln('  <g mask="url(#eraser_mask_${layer.id})">');
      } else {
        sb.writeln('  <g>');
      }

      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        if (stroke.isPixelEraser) continue;

        final color = stroke.color;
        final hexColor = '#${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
        final opacity = stroke.isTape ? (stroke.isTapeRevealed ? 0.2 : 0.95) : color.a;

        if (stroke.isInkPen) {
          final outline = stroke.outlinePolygon;
          if (outline.isEmpty) continue;

          sb.write('    <path d="');
          sb.write('M ${outline.first.dx} ${outline.first.dy} ');
          for (int i = 1; i < outline.length; i++) {
            sb.write('L ${outline[i].dx} ${outline[i].dy} ');
          }
          sb.write('Z" fill="$hexColor" fill-opacity="$opacity" />\n');
        } else {
          final pathPoints = stroke.points;
          if (pathPoints.length < 2) continue;

          sb.write('    <path d="');
          sb.write('M ${pathPoints.first.point.dx} ${pathPoints.first.point.dy} ');
          if (pathPoints.length == 2) {
            sb.write('L ${pathPoints[1].point.dx} ${pathPoints[1].point.dy} ');
          } else {
            for (int i = 1; i < pathPoints.length - 1; i++) {
              final p0 = pathPoints[i].point;
              final p1 = pathPoints[i + 1].point;
              final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
              sb.write('Q ${p0.dx} ${p0.dy} ${mid.dx} ${mid.dy} ');
            }
            sb.write('L ${pathPoints.last.point.dx} ${pathPoints.last.point.dy} ');
          }
          sb.write('" fill="none" stroke="$hexColor" stroke-width="${stroke.baseWidth}" stroke-linecap="round" stroke-linejoin="round" stroke-opacity="$opacity" />\n');
        }
      }
      
      sb.writeln('  </g>');
    }

    sb.writeln('</g>');
    sb.writeln('</svg>');

    final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
    await _saveOrShare(bytes, fileName, 'svg');
  }

  static Future<void> exportToImage(
    BuildContext context,
    List<CanvasLayer> layers, {
    Rect? cropRect,
    String fileName = 'horizon_export',
    bool includeGrid = false,
    bool transparentBackground = false,
    CanvasBackgroundVariant backgroundVariant = CanvasBackgroundVariant.none,
  }) async {
    final bounds = _calculateCanvasBounds(layers);
    final format = cropRect ?? bounds;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, format.width, format.height));

    if (!transparentBackground) {
      canvas.drawRect(Rect.fromLTWH(0, 0, format.width, format.height), Paint()..color = Colors.white);
    }

    if (includeGrid && backgroundVariant != CanvasBackgroundVariant.none) {
      final transform = TransformationController();
      transform.value.translate(
        (cropRect != null) ? -cropRect.left : -bounds.left,
        (cropRect != null) ? -cropRect.top : -bounds.top,
      );
      final painter = CanvasBackgroundPainter(
        variant: backgroundVariant,
        size: 40.0,
        fill: const Color(0xFF252525).withValues(alpha: 0.1),
        transform: transform,
        isLimitedBounds: false,
      );
      painter.paint(canvas, Size(format.width, format.height));
    }

    if (cropRect != null) {
      canvas.translate(-cropRect.left, -cropRect.top);
    } else {
      canvas.translate(-bounds.left, -bounds.top);
    }

    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final imageNode in layer.imageNodes) {
        if (imageNode.filePath.isEmpty) continue;
        try {
          final file = File(imageNode.filePath);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;

            canvas.save();
            canvas.translate(imageNode.position.dx + imageNode.width / 2, imageNode.position.dy + imageNode.height / 2);
            canvas.rotate(imageNode.rotation);
            canvas.scale(imageNode.scale);
            canvas.translate(-imageNode.width / 2, -imageNode.height / 2);

            paintImage(
              canvas: canvas,
              rect: Rect.fromLTWH(0, 0, imageNode.width, imageNode.height),
              image: image,
              fit: BoxFit.fill,
            );

            canvas.restore();
          }
        } catch (e) {
          debugPrint("Failed to export image node: $e");
        }
      }

      canvas.saveLayer(null, Paint());

      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;

        final paint = Paint()
          ..color = stroke.color
          ..style = (!stroke.isInkPen && !stroke.isPixelEraser) ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = stroke.baseWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (stroke.isPixelEraser) {
          paint.blendMode = BlendMode.clear;
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = stroke.baseWidth;
        } else if (stroke.isTape) {
          if (stroke.isTapeRevealed) {
            paint.color = stroke.color.withValues(alpha: 0.2);
          } else {
            paint.color = stroke.color.withValues(alpha: 0.95);
          }
        }

        canvas.drawPath(stroke.path, paint);
      }

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(format.width.toInt(), format.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();

    if (bytes != null) {
      await _saveOrShare(bytes, fileName, 'png');
    }
  }


}

void _paintPdfCanvas(
  PdfGraphics canvas,
  PdfPoint size,
  List<CanvasLayer> layers, {
  Offset offset = Offset.zero,
}) {
  for (var layer in layers) {
    if (!layer.isVisible) continue;

    for (var stroke in layer.strokes) {
      if (stroke.points.isEmpty) continue;

      canvas.saveContext();
      if (!stroke.isPixelEraser && stroke.color == Colors.transparent) {
        canvas.restoreContext();
        continue;
      }

      final color = stroke.isPixelEraser 
          ? PdfColors.white 
          : PdfColor(
              stroke.color.r,
              stroke.color.g,
              stroke.color.b,
              stroke.color.a,
            );

      canvas.setFillColor(color);

      if (stroke.isInkPen && !stroke.isPixelEraser) {
        final outline = stroke.outlinePolygon;
        if (outline.isNotEmpty) {
          final start = outline.first;
          canvas.moveTo(start.dx + offset.dx, size.y - (start.dy + offset.dy));
          for (int i = 1; i < outline.length; i++) {
            final pt = outline[i];
            canvas.lineTo(pt.dx + offset.dx, size.y - (pt.dy + offset.dy));
          }
          canvas.fillPath();
        }
      } else {
        canvas.setStrokeColor(color);
        canvas.setLineWidth(stroke.baseWidth);
        final pathPoints = stroke.points;
        if (pathPoints.length >= 2) {
          final start = pathPoints.first.point;
          canvas.moveTo(start.dx + offset.dx, size.y - (start.dy + offset.dy));
          for (int i = 1; i < pathPoints.length; i++) {
            final pt = pathPoints[i].point;
            canvas.lineTo(pt.dx + offset.dx, size.y - (pt.dy + offset.dy));
          }
          canvas.strokePath();
        }
      }
      canvas.restoreContext();
    }
  }
}
