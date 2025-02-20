import 'dart:convert';
import 'dart:typed_data';

import 'package:karyo_wise/data/model/chromosome_model.dart';
import 'package:karyo_wise/data/model/metaphase_model.dart';
import 'package:karyo_wise/data/provider/segment_api.dart';

class SegmentService {
  final _api = SegmentAPI();

  Future<List<Chromosome>?> segmentMetaphaseImage(imageUrl) async {
    Uint8List? image = await getImageFromUrl(imageUrl);
    if (image != null) {
      String? base64Image = base64Encode(image);
      return _api.segmentMetaphaseImage(base64Image);
    } else {
      return null;
    }
  }

  Future<List<Metaphase>?> getMetaphaseImages() async {
    return _api.getMetaphaseImages();
  }

  Future<Uint8List?> getImageFromUrl(imageUrl) async {
    return _api.getImageFromUrl(imageUrl);
  }
}
