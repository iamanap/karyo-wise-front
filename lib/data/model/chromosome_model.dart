import 'dart:convert';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:flutter/material.dart';

List<Chromosome> chromosomeFromJson(String str) =>
    List<Chromosome>.from(json.decode(str).map((x) => Chromosome.fromJson(x)));

String chromosomeToJson(List<Chromosome> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Chromosome {
  int label;
  double score;
  final List<Offset> polygon;
  final Offset startPoints;
  final ui.Size boxSize;
  String? uri;
  Chromosome(
      {required this.label,
      required this.score,
      required this.polygon,
      required this.startPoints,
      required this.boxSize,
      this.uri});

  Map<String, dynamic> toJson() => {
        "points": List<dynamic>.from(polygon.map((offset) => List<Offset>)),
        "label": label,
        "x": startPoints.dx.toInt(),
        "y": startPoints.dy.toInt(),
        "width": boxSize.width.toInt(),
        "height": boxSize.height.toInt(),
      };

  factory Chromosome.fromJson(Map<String, dynamic> json) => Chromosome(
        label: json["label"],
        score: json["score"],
        startPoints: Offset(json["x"]?.toDouble(), json["y"]?.toDouble()),
        boxSize: ui.Size(json["width"]?.toDouble(), json["height"]?.toDouble()),
        polygon: (json["points"] as List).map((point) {
          double x = point[0].toDouble();
          double y = point[1].toDouble();
          return Offset(x, y);
        }).toList(),
      );

  Color? getColor() {
    return _labelColors[label - 1];
  }

  final List<Color> _labelColors = [
    Colors.cyan,
    fluent_ui.Colors.yellow.normal,
    fluent_ui.Colors.orange.darkest,
    fluent_ui.Colors.orange.normal,
    fluent_ui.Colors.red.darkest,
    fluent_ui.Colors.red.normal,
    fluent_ui.Colors.magenta.darkest,
    fluent_ui.Colors.magenta.normal,
    fluent_ui.Colors.blue.darkest,
    fluent_ui.Colors.blue.normal,
    fluent_ui.Colors.green.darkest,
    fluent_ui.Colors.green.normal,
    Colors.pink,
    fluent_ui.Colors.orange.lightest,
    fluent_ui.Colors.red.lightest,
    fluent_ui.Colors.magenta.lightest,
    fluent_ui.Colors.blue.lightest,
    fluent_ui.Colors.green.lightest,
    fluent_ui.Colors.purple.darkest,
    fluent_ui.Colors.purple.normal,
    fluent_ui.Colors.purple.lightest,
    fluent_ui.Colors.teal.normal,
    fluent_ui.Colors.teal.darkest,
    fluent_ui.Colors.yellow.darker
  ];
}
