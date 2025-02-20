import 'dart:io';

import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:karyo_wise/data/model/chromosome_model.dart';
import 'package:flutter/material.dart';
import 'package:karyo_wise/constants.dart';
import 'package:karyo_wise/data/model/metaphase_model.dart';
import 'package:karyo_wise/data/provider/segment_api.dart';
import 'package:karyo_wise/data/service/segment_service.dart';
import 'package:path_provider/path_provider.dart' as syspaths;

class ImageCropper {
  SegmentAPI segmentAPI;
  ImageCropper({required this.segmentAPI});

  Future<List<String>?> cropAllChromosomes(
      List<Chromosome> chromosomes, Metaphase metaphase) async {
    Uint8List? oriImage = await segmentAPI.getImageFromUrl(metaphase.url);
    if (oriImage != null) {
      ui.Image originalImage = await decodeImageFromList(oriImage);
      List<String> filePaths = [];
      for (Chromosome chromosome in chromosomes) {
        String filePath =
            await _cropImagePolygon(originalImage, metaphase.name, chromosome);
        filePaths.add(filePath);
      }
      return filePaths;
    } else {
      return null;
    }
  }

  Future<String> _cropImagePolygon(
      ui.Image originalImage, String imgName, Chromosome chromosome) async {
    imgName = imgName.replaceAll(' ', '_');
    // Create a mask based on the polygon points
    ui.Image maskImage = await _createMask(
        originalImage.width, originalImage.height, chromosome.polygon);

    // Apply the mask to the original image
    ui.Image maskedImage = await _applyMask(originalImage, maskImage);

    ui.Image croppedImage = await _cropImage(
        maskedImage,
        Rect.fromLTWH(chromosome.startPoints.dx, chromosome.startPoints.dy,
            chromosome.boxSize.width, chromosome.boxSize.height));

    // Convert the resulting image to bytes
    ByteData? byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    List<int> resultBytes = byteData!.buffer.asUint8List();

    // Save the result as a File
    final appDir = await syspaths.getTemporaryDirectory();
    String folderName = tempAppFolder;
    Directory folderDir = Directory('${appDir.path}/$folderName');
    if (!(await folderDir.exists())) {
      // If the folder doesn't exist, create it
      await folderDir.create(recursive: true);
    }
    File resultFile =
        File('${folderDir.path}/${imgName}_${chromosome.label}.jpg');
    if (await resultFile.exists()) {
      resultFile =
          File('${folderDir.path}/${imgName}_${chromosome.label}_2.jpg');
      if (await resultFile.exists()) {
        resultFile =
            File('${folderDir.path}/${imgName}_${chromosome.label}_3.jpg');
      }
    }
    print('${folderDir.path}/${imgName}_${chromosome.label}.jpg');
    await resultFile.writeAsBytes(resultBytes);

    return resultFile.path;
  }

  Future<ui.Image> _createMask(
      int width, int height, List<Offset> points) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    // Draw the polygon on the mask
    canvas.drawPicture(_createMaskPicture(points, width, height));

    // Convert the recorder to an Image
    return await recorder.endRecording().toImage(width, height);
  }

  ui.Picture _createMaskPicture(List<Offset> points, int width, int height) {
    ui.Path path = ui.Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.drawPath(path, Paint());

    return recorder.endRecording();
  }

  Future<ui.Image> _applyMask(ui.Image original, ui.Image mask) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    // Draw the original image
    canvas.drawImage(original, Offset.zero, Paint());

    // Apply the mask
    Paint maskPaint = Paint()..blendMode = ui.BlendMode.dstIn;
    canvas.drawImage(mask, Offset.zero, maskPaint);

    // Convert the recorder to an Image
    return await recorder
        .endRecording()
        .toImage(original.width, original.height);
  }

  Future<ui.Image> _cropImage(ui.Image image, Rect cropRect) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    // Draw the cropped image
    canvas.drawImageRect(
        image,
        cropRect,
        Rect.fromPoints(Offset.zero, Offset(cropRect.width, cropRect.height)),
        Paint());

    // Convert the recorder to an Image
    return await recorder
        .endRecording()
        .toImage(cropRect.width.toInt(), cropRect.height.toInt());
  }

  Future<void> deleteTempFiles(List<String?> filePaths) async {
    for (String? filePath in filePaths) {
      if (filePath != null) {
        File file = File(filePath);
        if (file.existsSync()) file.deleteSync(recursive: true);
      }
    }
  }
}
