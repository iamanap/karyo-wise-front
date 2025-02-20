import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:karyo_wise/data/model/chromosome_model.dart';
import 'package:karyo_wise/data/model/metaphase_model.dart';

class SegmentAPI {
  final _endpoint =
      'https://kax63zuh7g.execute-api.us-east-1.amazonaws.com/test/';

  Future<List<Chromosome>?> segmentMetaphaseImage(imageBase64) async {
    // var uri = Uri.parse('${_endpoint}segmentMetaphaseImage');
    // final response = await http.post(
    //   uri,
    //   headers: <String, String>{
    //     'Content-Type': 'application/json; charset=UTF-8',
    //   },
    //   body: jsonEncode(<String, String>{
    //     'image': imageBase64,
    //   }),
    // );
    // if (response.statusCode == 200) {
    //   return chromosomeFromJson(
    //       const Utf8Decoder().convert(response.bodyBytes));
    // }
    // return null;
    String data = await rootBundle.loadString("assets/original_1_rcnn.json");
    return chromosomeFromJson(data);
  }

  Future<List<Metaphase>?> getMetaphaseImages() async {
    var uri = Uri.parse('${_endpoint}getMetaphaseImages');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      return metaphaseFromJson(const Utf8Decoder().convert(response.bodyBytes));
    }
    return null;
  }

  Future<Uint8List?> getImageFromUrl(imageUrl) async {
    var uri = Uri.parse(imageUrl);
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      return bytes;
    }
    return null;
  }
}
