import 'dart:convert';
import 'dart:ui';

List<Metaphase> metaphaseFromJson(String str) =>
    List<Metaphase>.from(json.decode(str).map((x) => Metaphase.fromJson(x)));

String metaphaseToJson(List<Metaphase> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Metaphase {
  String name;
  final Size imgSize;
  String url;

  Metaphase({required this.name, required this.url, required this.imgSize});

  factory Metaphase.fromJson(Map<String, dynamic> json) => Metaphase(
        name: json["name"],
        url: json["url"],
        imgSize: Size(json["width"]?.toDouble(), json["height"]?.toDouble()),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "url": url,
        "width": imgSize.width.toInt(),
        "height": imgSize.height.toInt(),
      };
}
