// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/canvas_objects.dart';
import 'dart:convert';
import 'dart:typed_data';

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

    // Add some padding
    return Rect.fromLTRB(minX - 50, minY - 50, maxX + 50, maxY + 50);
  }

  static Future<void> exportToPdf(
    List<CanvasLayer> layers, {
    String canvasType = 'infinite',
    Rect? cropRect,
    String fileName = 'horizon_export',
  }) async {
    final bounds = _calculateCanvasBounds(layers);
    final pdf = pw.Document();

    final pageFormat = cropRect != null
        ? PdfPageFormat(cropRect.width, cropRect.height)
        : (canvasType == 'a4'
            ? PdfPageFormat.a4
            : PdfPageFormat(bounds.width, bounds.height));

    // Preload images for PDF
    final pdfImages = <String, pw.MemoryImage>{};
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

          // 1. Draw Images
          for (final layer in layers) {
            if (!layer.isVisible) continue;
            for (final node in layer.imageNodes) {
              if (pdfImages.containsKey(node.id)) {
                 children.add(
                   pw.Positioned(
                     left: node.position.dx + offset.dx,
                     // PDF coordinate system originates from bottom-left, but pw.Positioned 
                     // in a pw.Stack correctly maps `top` from the top-left of the Stack.
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
          }

          // 2. Draw Strokes
          children.add(
            pw.Positioned(
              left: 0,
              top: 0,
              child: pw.CustomPaint(
                size: paintSize,
                painter: (PdfGraphics canvas, PdfPoint size) {
                  _paintPdfCanvas(canvas, size, layers, offset: offset);
                },
              )
            )
          );

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
    await Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');
  }

  static Future<void> exportToSvg(
    BuildContext context,
    List<CanvasLayer> layers, {
    Rect? cropRect,
    String fileName = 'horizon_export',
  }) async {
    final bounds = _calculateCanvasBounds(layers);
    final format = cropRect ?? bounds;

    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    sb.writeln('<svg width="${format.width}" height="${format.height}" viewBox="0 0 ${format.width} ${format.height}" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
    sb.writeln('<rect width="100%" height="100%" fill="white"/>');
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
      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty || stroke.isPixelEraser || stroke.color == Colors.transparent) continue;

        final color = stroke.color;
        final hexColor = '#${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
        final opacity = stroke.isTape ? (stroke.isTapeRevealed ? 0.2 : 0.95) : color.a;

        if (stroke.isInkPen) {
          final outline = stroke.outlinePolygon;
          if (outline.isEmpty) continue;

          sb.write('<path d="');
          sb.write('M ${outline.first.dx} ${outline.first.dy} ');
          for (int i = 1; i < outline.length; i++) {
            sb.write('L ${outline[i].dx} ${outline[i].dy} ');
          }
          sb.write('Z" fill="$hexColor" fill-opacity="$opacity" />\n');
        } else {
          final pathPoints = stroke.points;
          if (pathPoints.length < 2) continue;

          sb.write('<path d="');
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
    }

    sb.writeln('</g>');
    sb.writeln('</svg>');

    final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
    await Printing.sharePdf(bytes: bytes, filename: '$fileName.svg');
  }

  static Future<void> exportToImage(
    BuildContext context,
    List<CanvasLayer> layers, {
    Rect? cropRect,
    String fileName = 'horizon_export',
  }) async {
    final bounds = _calculateCanvasBounds(layers);
    final format = cropRect ?? bounds;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, format.width, format.height));
    
    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, format.width, format.height), Paint()..color = Colors.white);
    
    if (cropRect != null) {
      canvas.translate(-cropRect.left, -cropRect.top);
    } else {
      canvas.translate(-bounds.left, -bounds.top);
    }
    
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      // Draw Images
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

      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        
        final paint = Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill;
          
        if (stroke.isPixelEraser) {
          paint.blendMode = BlendMode.clear;
        } else if (stroke.isTape) {
          paint.color = stroke.color.withValues(alpha: stroke.isTapeRevealed ? 0.2 : 0.95);
        }
        
        canvas.drawPath(stroke.path, paint);
      }
    }
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(format.width.toInt(), format.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    
    if (bytes != null) {
      // Using Printing.sharePdf to share the image bytes, it supports general sharing
      await Printing.sharePdf(bytes: bytes, filename: '$fileName.png');
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
      if (stroke.isPixelEraser || stroke.color == Colors.transparent) {
        canvas.restoreContext();
        continue;
      }

      final color = PdfColor(
        stroke.color.r,
        stroke.color.g,
        stroke.color.b,
        stroke.color.a,
      );

      canvas.setFillColor(color);

      if (stroke.isInkPen) {
        // Draw variable width
        for (int i = 0; i < stroke.points.length - 1; i++) {
          final p1 = stroke.points[i];
          final p2 = stroke.points[i + 1];
          final w1 = stroke.baseWidth * p1.pressure;
          final w2 = stroke.baseWidth * p2.pressure;

          final dx1 = p1.point.dx + offset.dx;
          final dy1 = size.y - (p1.point.dy + offset.dy);
          final dx2 = p2.point.dx + offset.dx;
          final dy2 = size.y - (p2.point.dy + offset.dy);

          canvas.drawEllipse(dx1, dy1, w1, w1);
          canvas.drawEllipse(dx2, dy2, w2, w2);
          // Connect them
          canvas.setStrokeColor(color);
          canvas.setLineWidth(w1);
          canvas.drawLine(dx1, dy1, dx2, dy2);
          canvas.strokePath();
        }
      } else {
        // Draw constant width
        canvas.setStrokeColor(color);
        canvas.setLineWidth(stroke.baseWidth);
        for (int i = 0; i < stroke.points.length - 1; i++) {
          final p1 = stroke.points[i];
          final p2 = stroke.points[i + 1];
          
          final dx1 = p1.point.dx + offset.dx;
          final dy1 = size.y - (p1.point.dy + offset.dy);
          final dx2 = p2.point.dx + offset.dx;
          final dy2 = size.y - (p2.point.dy + offset.dy);
          
          canvas.drawLine(dx1, dy1, dx2, dy2);
          canvas.strokePath();
        }
      }

      canvas.fillPath();
      canvas.restoreContext();
    }
  }
}
