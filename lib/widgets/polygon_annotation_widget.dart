import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:karyo_wise/data/model/chromosome_model.dart';
import 'package:karyo_wise/constants.dart';
import 'package:karyo_wise/data/model/metaphase_model.dart';
import 'package:karyo_wise/data/service/segment_service.dart';
import 'package:karyo_wise/widgets/class_overlay_widget.dart';
import 'package:window_manager/window_manager.dart';

class PolygonAnnotationWidget extends StatefulWidget {
  final ValueChanged<List<Chromosome>?> finalChromosomesAction;
  final Metaphase? metaphase;
  final bool drag;
  final bool manualPolygon;

  const PolygonAnnotationWidget(
      {super.key,
      required this.metaphase,
      required this.drag,
      required this.manualPolygon,
      required this.finalChromosomesAction});

  @override
  State<StatefulWidget> createState() => _PolygonAnnotationWidget();
}

class _PolygonAnnotationWidget extends State<PolygonAnnotationWidget>
    with WindowListener {
  Size? _imgSize;
  // (double, double)? imgScaleFactor;
  final bool _isOverlayVisible = true;
  Chromosome? _hoveredChromosome;
  bool _isHoveringChromosome = false;
  Chromosome? _selectedChromosome;

  List<Chromosome> _fetchedPolygons = [];
  List<Chromosome> _scaledFetchedPolygons = [];
  List<Offset> _currentPolygon = [];
  Offset? _currentCursorPoint;
  Offset? _hoveredPoint;
  bool pointerMoved = false;

  bool _isClassOverlayVisible = false;

  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _classOverlayKey = GlobalKey();
  final GlobalKey _mouseKey = GlobalKey();

  @override
  void initState() {
    windowManager.addListener(this);
    if (widget.metaphase != null) {
      // pointsToPolygon().then((value) => {
      //       setState(() {
      //         _fetchedPolygons = value;
      //         updateScaleFactor();
      //       })
      //     });
      if (_fetchedPolygons.isEmpty) {
        fetchChromosomes(widget.metaphase!.url);
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResize() {
    updateScaleFactor();
  }

  @override
  Widget build(BuildContext context) {
    Image img = Image.network(
      widget.metaphase?.url ?? '',
      key: _imageKey,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );

    _runsAfterBuild();
    return RawKeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKey: (event) => {
              if (event.isKeyPressed(LogicalKeyboardKey.delete))
                {
                  setState(() {
                    if (_hoveredPoint == null) {
                      deletePolygon();
                    } else {
                      tryToDeleteHoveredPoint();
                    }
                  })
                }
            },
        child: MouseRegion(
          key: _mouseKey,
          cursor: getMouseCursor(),
          onEnter: (_) {
            setState(() {
              _currentCursorPoint = null;
            });
          },
          onExit: (_) {
            setState(() {
              _currentCursorPoint = null;
            });
          },
          child: Listener(
            onPointerMove: (PointerMoveEvent event) {
              pointerMoved = true;
              setState(() {
                movePointInPolygon(context, event);
              });
            },
            onPointerDown: (PointerDownEvent event) {
              pointerMoved = false;
            },
            onPointerUp: (PointerUpEvent event) {
              setState(() {
                onClick(context, event);
              });
              pointerMoved = false;
            },
            onPointerHover: (PointerHoverEvent event) {
              setState(() {
                if (widget.manualPolygon || widget.drag) {
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  _currentCursorPoint = renderBox.globalToLocal(event.position);
                  setCursorHoveringPoint(_currentCursorPoint!);
                }
              });
              if (widget.drag && (_scaledFetchedPolygons.isNotEmpty)) {
                updateHoveredChromosome(event.localPosition);
              }
            },
            child: widget.metaphase == null
                ? const SizedBox.shrink()
                : Stack(
                    children: [
                      img,
                      Visibility(
                          visible: _isOverlayVisible,
                          child: Container(color: Colors.black26)),
                      CustomPaint(
                        painter: PolygonPainter(
                            scaledFetchedPolygons: _scaledFetchedPolygons,
                            currentPolygon: _currentPolygon,
                            currentCursorPoint: _currentCursorPoint,
                            hoveredChromosome: _hoveredChromosome,
                            selecteChromosome: _selectedChromosome,
                            hoveredPoint: _hoveredPoint),
                        size: Size(
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height,
                        ),
                      ),
                      Visibility(
                          visible: _isClassOverlayVisible,
                          child: ClassOverlayWidget(
                              key: _classOverlayKey,
                              classIndex: _selectedChromosome != null
                                  ? _selectedChromosome!.label
                                  : 1,
                              onDeletePressed: _onDeletePressed,
                              onSavePressed: _onSavePressed))
                    ],
                  ),
          ),
        ));
  }

  void _onDeletePressed(index) {
    deletePolygon();
    _isClassOverlayVisible = false;
    _selectedChromosome = _hoveredChromosome;
  }

  void _onSavePressed(index) {
    if (widget.manualPolygon || widget.drag) {
      _changeChromosomeClass(index);
    }
    _isClassOverlayVisible = false;
    _selectedChromosome = _hoveredChromosome;
  }

  void _addNewChromosome(index) {
    Rect polygonBbox = findPolygonBoundingBox(_currentPolygon);
    _currentCursorPoint = null;
    var newChromosome = Chromosome(
        label: 1,
        score: 1.0,
        polygon: _currentPolygon,
        startPoints: Offset(polygonBbox.left, polygonBbox.top),
        boxSize: polygonBbox.size);
    _scaledFetchedPolygons.add(newChromosome);
    _currentPolygon = [];
    _selectedChromosome = _scaledFetchedPolygons.last;
  }

  void _changeChromosomeClass(index) {
    if (_selectedChromosome != null) {
      var polygonIndex = _scaledFetchedPolygons.indexOf(_selectedChromosome!);
      if (polygonIndex > -1) {
        _scaledFetchedPolygons.elementAt(polygonIndex).label = index + 1;
      }
    }
  }

  void onClick(fluent_ui.BuildContext context, fluent_ui.PointerUpEvent event) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset clickPoint = renderBox.globalToLocal(event.position);
    if (_isClickOnClassOverlay(clickPoint)) {
      return;
    }
    if (widget.manualPolygon) {
      if (_currentPolygon.isNotEmpty &&
          (_currentPolygon.first - clickPoint).distance <= 10.0) {
        _addNewChromosome(0);
        _isClassOverlayVisible = true;
      } else {
        _currentPolygon.add(clickPoint);
      }
    } else if (widget.drag) {
      _selectedChromosome = _hoveredChromosome;
      _isClassOverlayVisible = _selectedChromosome != null;
      if (!pointerMoved) {
        tryToDeleteHoveredPoint();
      }
    }
  }

  bool _isClickOnClassOverlay(clickPoint) {
    final keyContext = _classOverlayKey.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      BoxHitTestResult result = BoxHitTestResult();
      box.hitTest(result, position: clickPoint);
      return result.path.isNotEmpty;
    }
    return false;
  }

  void movePointInPolygon(
      fluent_ui.BuildContext context, fluent_ui.PointerMoveEvent event) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset clickPoint = renderBox.globalToLocal(event.position);
    if (_selectedChromosome != null && _hoveredPoint != null) {
      var polygonIndex = _scaledFetchedPolygons.indexOf(_selectedChromosome!);
      if (polygonIndex > -1) {
        var pointIndex = _scaledFetchedPolygons
            .elementAt(polygonIndex)
            .polygon
            .indexOf(_hoveredPoint!);
        if (pointIndex > -1) {
          _scaledFetchedPolygons.elementAt(polygonIndex).polygon[pointIndex] =
              clickPoint;
          var imgScaleFactor = getXYScaleFactor();
          _fetchedPolygons.elementAt(polygonIndex).polygon[pointIndex] = Offset(
              clickPoint.dx / imgScaleFactor!.$1,
              clickPoint.dy / imgScaleFactor.$2);
        }
      }
      var pointIndex = _selectedChromosome!.polygon.indexOf(_hoveredPoint!);
      if (pointIndex > -1) {
        _selectedChromosome!.polygon[pointIndex] = clickPoint;
      }
      _hoveredPoint = clickPoint;
    }
  }

  void tryToDeleteHoveredPoint() {
    if (_selectedChromosome != null && _hoveredPoint != null) {
      var polygonIndex = _scaledFetchedPolygons.indexOf(_selectedChromosome!);
      if (polygonIndex > -1) {
        var pointIndex = _scaledFetchedPolygons
            .elementAt(polygonIndex)
            .polygon
            .indexOf(_hoveredPoint!);
        if (pointIndex > -1) {
          _scaledFetchedPolygons
              .elementAt(polygonIndex)
              .polygon
              .removeAt(pointIndex);
          _fetchedPolygons.elementAt(polygonIndex).polygon.removeAt(pointIndex);
          print('Removed point');
          if (_scaledFetchedPolygons.elementAt(polygonIndex).polygon.length <
              3) {
            _scaledFetchedPolygons.removeAt(polygonIndex);
            _fetchedPolygons.removeAt(polygonIndex);
            print('Removed polygon');
          }
        }
      }
      _selectedChromosome!.polygon.remove(_hoveredPoint);
    }
  }

  void deletePolygon() {
    if (_selectedChromosome != null) {
      var polygonIndex = _scaledFetchedPolygons.indexOf(_selectedChromosome!);
      if (polygonIndex > -1) {
        _scaledFetchedPolygons.removeAt(polygonIndex);
        _fetchedPolygons.removeAt(polygonIndex);
      }
      _selectedChromosome = null;
      _isClassOverlayVisible = false;
    }
  }

  Rect findPolygonBoundingBox(List<Offset> polygon) {
    if (polygon.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (Offset point in polygon) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Future<void> _runsAfterBuild() async {
    if (_imgSize == null) {
      updateScaleFactor();
    }
  }

  SystemMouseCursor getMouseCursor() {
    if (_isHoveringChromosome && !widget.manualPolygon) {
      return fluent_ui.SystemMouseCursors.grab;
    } else if (widget.manualPolygon && !_isClassOverlayVisible) {
      return fluent_ui.SystemMouseCursors.precise;
    } else {
      return fluent_ui.SystemMouseCursors.basic;
    }
  }

  void updateScaleFactor() {
    setState(() {
      var imgScaleFactor = getXYScaleFactor();
      if (imgScaleFactor != null) {
        _scaledFetchedPolygons = [];

        for (Chromosome chromosome in _fetchedPolygons) {
          List<Offset> scaledPolygon = [];
          for (Offset point in chromosome.polygon) {
            scaledPolygon.add(Offset(
                point.dx * imgScaleFactor.$1, point.dy * imgScaleFactor.$2));
          }

          Rect polygonBbox = findPolygonBoundingBox(scaledPolygon);
          _scaledFetchedPolygons.add(Chromosome(
              label: chromosome.label,
              score: chromosome.score,
              polygon: scaledPolygon,
              startPoints: Offset(polygonBbox.left, polygonBbox.top),
              boxSize: polygonBbox.size));
        }
      }
      widget.finalChromosomesAction(geatRealImageSizePolygons());
    });
  }

  (double, double)? getCurrentImageSize() {
    final keyContext = _imageKey.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      return (box.size.width, box.size.height);
    }
    return null;
  }

  (double, double)? getXYScaleFactor() {
    var currentImgSize = getCurrentImageSize();
    if (currentImgSize != null) {
      _imgSize = widget.metaphase!.imgSize;
      var imgWidth = _imgSize?.width ?? 1;
      var imgHeight = _imgSize?.height ?? 1;
      double xScaleFactor = currentImgSize.$1 > imgWidth
          ? imgWidth / currentImgSize.$1
          : currentImgSize.$1 / imgWidth;
      double yScaleFactor = currentImgSize.$2 > imgHeight
          ? imgHeight / currentImgSize.$2
          : currentImgSize.$2 / imgHeight;
      return (xScaleFactor, yScaleFactor);
    } else {
      return null;
    }
  }

  List<Chromosome>? geatRealImageSizePolygons() {
    List<Chromosome> finalPolygons = [];
    var imgScaleFactor = getXYScaleFactor();
    if (imgScaleFactor == null) return null;
    for (Chromosome chromosome in _scaledFetchedPolygons) {
      List<Offset> scaledPolygon = [];
      for (Offset point in chromosome.polygon) {
        scaledPolygon.add(
            Offset(point.dx / imgScaleFactor.$1, point.dy / imgScaleFactor.$2));
      }
      Rect polygonBbox = findPolygonBoundingBox(scaledPolygon);
      finalPolygons.add(Chromosome(
          label: chromosome.label,
          score: chromosome.score,
          polygon: scaledPolygon,
          startPoints: Offset(polygonBbox.left, polygonBbox.top),
          boxSize: polygonBbox.size));
    }
    return finalPolygons;
  }

  Future<void> fetchChromosomes(imageUrl) async {
    final segmentService = SegmentService();
    _fetchedPolygons = (await segmentService.segmentMetaphaseImage(imageUrl))!;
    setState(() {
      updateScaleFactor();
    });
  }

  void updateHoveredChromosome(Offset cursorPosition) {
    setState(() {
      _hoveredChromosome = getHoveredChromosome(cursorPosition);
    });
  }

  Chromosome? getHoveredChromosome(Offset cursorPosition) {
    for (Chromosome chromosome in _scaledFetchedPolygons) {
      if (isPointInsidePolygon(cursorPosition, chromosome.polygon)) {
        _isHoveringChromosome = true;
        return chromosome;
      }
    }
    _isHoveringChromosome = false;
    return null;
  }

  bool isPointInsidePolygon(Offset point, List<Offset> polygon) {
    int wn = 0; // Winding number counter

    for (int i = 0; i < polygon.length; i++) {
      Offset v1 = polygon[i];
      Offset v2 = polygon[(i + 1) % polygon.length];

      if (v1.dy <= point.dy) {
        if (v2.dy > point.dy && isLeft(v1, v2, point) > 0) {
          wn++;
        }
      } else {
        if (v2.dy <= point.dy && isLeft(v1, v2, point) < 0) {
          wn--;
        }
      }
    }

    return wn != 0;
  }

  double isLeft(Offset v1, Offset v2, Offset point) {
    return ((v2.dx - v1.dx) * (point.dy - v1.dy) -
        (point.dx - v1.dx) * (v2.dy - v1.dy));
  }

  void setCursorHoveringPoint(Offset cursorPosition) {
    if (_selectedChromosome == null) {
      _hoveredPoint = null;
      return;
    }
    for (Offset point in _selectedChromosome!.polygon) {
      double distance = (point - cursorPosition).distance;
      if (distance <= 5.0) {
        _hoveredPoint = point;
      } else {
        if (_hoveredChromosome == null) _hoveredPoint = null;
      }
    }
  }
}

class PolygonPainter extends CustomPainter {
  final List<Chromosome> scaledFetchedPolygons;
  // final List<Chromosome> drawnPolygons;
  final List<Offset> currentPolygon;
  final Offset? currentCursorPoint;
  Chromosome? hoveredChromosome;
  Chromosome? selecteChromosome;
  Offset? hoveredPoint;

  PolygonPainter(
      {required this.scaledFetchedPolygons,
      // required this.drawnPolygons,
      required this.currentPolygon,
      required this.hoveredChromosome,
      required this.selecteChromosome,
      required this.hoveredPoint,
      this.currentCursorPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paintLine = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint paintDot = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    if (currentPolygon.isNotEmpty && currentCursorPoint != null) {
      double distance = (currentPolygon.first - currentCursorPoint!).distance;
      bool hoveringOverFirstCircle = distance <= 10.0;

      if (hoveringOverFirstCircle && currentPolygon.length > 1) {
        canvas.drawCircle(currentPolygon.first, 6.0, paintDot);
      }

      canvas.drawLine(
        currentPolygon.last,
        currentCursorPoint!,
        paintLine,
      );
    }

    if (currentPolygon.isNotEmpty) {
      for (int i = 0; i < currentPolygon.length; i++) {
        canvas.drawCircle(currentPolygon[i], 3.0, paintDot);
        if (currentPolygon.length > i + 1) {
          canvas.drawLine(currentPolygon[i], currentPolygon[i + 1], paintLine);
        }
      }
    }
    for (Chromosome chromosome in scaledFetchedPolygons) {
      drawCompletePolygon(canvas, paintLine, paintDot, chromosome);
    }

    if (hoveredChromosome != null) {
      drawHoveredChromosomeLabel(canvas, hoveredChromosome!, size);
    }
  }

  void drawHoveredChromosomeLabel(
      Canvas canvas, Chromosome chromosome, Size size) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: getChromosomeLabelByIndex(chromosome.label),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    Offset toDrawnStartPoint =
        Offset(chromosome.startPoints.dx - 20, chromosome.startPoints.dy - 20);
    canvas.drawRect(
      Rect.fromLTWH(toDrawnStartPoint.dx, toDrawnStartPoint.dy,
          textPainter.width, textPainter.height),
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    textPainter.paint(
      canvas,
      toDrawnStartPoint,
    );
  }

  void drawCompletePolygon(
      Canvas canvas, Paint paintLine, Paint paintDot, Chromosome chromosome) {
    paintLine.color = chromosome.getColor() ?? Colors.blue;

    final Paint rectPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Paint rectStrokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (selecteChromosome != null) {
      paintLine.strokeWidth = 1.0;
      paintDot.color = selecteChromosome!.getColor()!;
      for (Offset point in selecteChromosome!.polygon) {
        if (point != hoveredPoint) {
          canvas.drawCircle(point, 4.0, paintDot);
        }
      }
      if (hoveredPoint != null) {
        final Rect pointRect = Rect.fromPoints(
          Offset(hoveredPoint!.dx - 5, hoveredPoint!.dy - 5),
          Offset(hoveredPoint!.dx + 5, hoveredPoint!.dy + 5),
        );
        canvas.drawRect(pointRect, rectPaint);
        canvas.drawRect(pointRect, rectStrokePaint);
      }
    }

    for (int i = 0; i < chromosome.polygon.length; i++) {
      paintLine.strokeWidth = 2.0;
      if (chromosome.polygon.length > i + 1) {
        canvas.drawLine(
          chromosome.polygon[i],
          chromosome.polygon[i + 1],
          paintLine,
        );
      }
    }
    canvas.drawLine(
        chromosome.polygon.last, chromosome.polygon.first, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
