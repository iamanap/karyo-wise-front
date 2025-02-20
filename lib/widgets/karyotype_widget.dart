import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:flutter/material.dart';
import 'package:karyo_wise/constants.dart';
import 'package:karyo_wise/data/model/chromosome_model.dart';
import 'package:karyo_wise/data/model/metaphase_model.dart';
import 'package:karyo_wise/data/provider/segment_api.dart';
import 'package:karyo_wise/utils/image_cropper.dart';
import 'package:window_manager/window_manager.dart';

class KaryotypeWidget extends StatefulWidget {
  final ValueNotifier<List<Chromosome>> finalChromosomesNotifier;
  final Metaphase? metaphase;
  const KaryotypeWidget(
      {super.key,
      required this.metaphase,
      required this.finalChromosomesNotifier});

  @override
  KaryotypeWidgetState createState() => KaryotypeWidgetState();
}

class KaryotypeWidgetState extends State<KaryotypeWidget> with WindowListener {
  List<Chromosome> _chromosomes = [];
  final ImageCropper _imageCropper = ImageCropper(segmentAPI: SegmentAPI());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    widget.finalChromosomesNotifier.addListener(() {
      _chromosomes = widget.finalChromosomesNotifier.value;
      if (_chromosomes.isNotEmpty && widget.metaphase != null) {
        _imageCropper.deleteTempFiles(
            _chromosomes.map((element) => element.uri).toList());
        _imageCropper
            .cropAllChromosomes(_chromosomes, widget.metaphase!)
            .then((uris) => setState(() {
                  if (uris != null) {
                    _isLoading = false;
                    for (final (index, uri) in uris.indexed) {
                      _chromosomes.elementAt(index).uri = uri;
                    }
                  }
                }));
      }
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _imageCropper
        .deleteTempFiles(_chromosomes.map((element) => element.uri!).toList());
    super.dispose();
  }

  @override
  void onWindowResize() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GridView.count(
          crossAxisCount: 8,
          childAspectRatio: 1.0,
          children: List.generate(_chromosomes.length, (index) {
            return Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  color: Colors.white,
                  width: (MediaQuery.of(context).size.width / 2) /
                      sqrt(_chromosomes.length),
                  height: MediaQuery.of(context).size.height /
                      (sqrt(_chromosomes.length) + 2),
                  child: Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(
                              12.0), // Adjust the padding as needed
                          child: SizedBox(
                            height: (MediaQuery.of(context).size.height /
                                    (sqrt(_chromosomes.length) + 4)) -
                                34,
                            child: Image.asset(
                              _chromosomes.elementAt(index).uri!,
                              fit: BoxFit.scaleDown,
                            ),
                          )),
                      Text(
                        '${getChromosomeLabelByIndex(_chromosomes.elementAt(index).label)} - ${_chromosomes.elementAt(index).score.toStringAsFixed(2)}',
                        style: fluent_ui.FluentTheme.of(context)
                            .typography
                            .caption,
                      ),
                    ],
                  ),
                ));
          })),
      Center(
          child: Visibility(
              visible: _isLoading, child: const fluent_ui.ProgressRing()))
    ]);
  }

  (double, double) calculateXYScaleFactor(double currentImageLayoutWidth,
      double currentImageLayoutHeight, Chromosome chromosome) {
    double imgWidth = chromosome.boxSize.width;
    double imgHeight = chromosome.boxSize.height;
    double xScaleFactor = currentImageLayoutWidth > imgWidth
        ? imgWidth / currentImageLayoutWidth
        : currentImageLayoutWidth / imgWidth;
    double yScaleFactor = currentImageLayoutHeight > imgHeight
        ? imgHeight / currentImageLayoutHeight
        : currentImageLayoutHeight / imgHeight;
    return (xScaleFactor, yScaleFactor);
  }
}

// class PolygonClipper extends CustomClipper<Path> {
//   final (double, double) Function(
//       double currentImageLayoutWidth,
//       double currentImageLayoutHeight,
//       Chromosome chromosome) calculateXYScaleFactor;
//   final ValueChanged<Size> imgSizeAction;
//   final Chromosome chromosome;
//   double zoomFactor = 2.0;
//   String imgString;

//   PolygonClipper(
//       {required this.chromosome,
//       required this.imgSizeAction,
//       required this.calculateXYScaleFactor,
//       required this.imgString});

//   @override
//   Path getClip(Size size) {
//     imgSizeAction(size);
//     Path path = Path();
//     if (size.width != 0 && size.height != 0) {
//       var imgScaleFactor =
//           calculateXYScaleFactor(size.width, size.height, chromosome);
//       var xScaleFactor = 1;
//       var yScaleFactor = 1;

//       double firstDx =
//           (chromosome.polygon.first.dx - chromosome.startPoints.dx) *
//               xScaleFactor;
//       double firstDy =
//           (chromosome.startPoints.dy - chromosome.polygon.first.dy) *
//               yScaleFactor;

//       path.moveTo(firstDx, firstDy);
//       // Draw the clipped path after applying translation
//       for (int i = 1; i < chromosome.polygon.length; i++) {
//         path.lineTo(
//             (chromosome.polygon[i].dx - chromosome.startPoints.dx) *
//                 xScaleFactor,
//             (chromosome.startPoints.dy - chromosome.polygon[i].dy) *
//                 yScaleFactor);
//       }
//       path.lineTo(firstDx, firstDy);
//       path.addPolygon(chromosome.polygon, true);
//     }
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
//     return false;
//   }
// }
