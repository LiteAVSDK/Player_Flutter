// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// Video progress bar, double progress.
/// 视频进度条，双进度
class VideoSlider extends StatefulWidget {
  late final VideoSliderController controller;

  final double? progressHeight;
  final double min;
  final double max;
  final double value;
  final double? bufferedValue;
  final double? sliderRadius;
  final double? sliderOutterRadius;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? bufferedColor;
  final Color? sliderColor;
  final Color? sliderOutterColor;
  final List<SliderPoint>? playPoints;
  final bool? canDrag;

  // callback
  final Function? onDragStart;
  final Function(double value)? onDragUpdate;
  final Function(double value)? onDragEnd;
  final Function(double pointX, int pos)? onPointClick;

  VideoSlider(
      {this.progressHeight,
      required this.min,
      required this.max,
      required this.value,
      this.bufferedValue,
      this.sliderRadius,
      this.sliderOutterRadius,
      this.activeColor,
      this.inactiveColor,
      this.bufferedColor,
      this.sliderColor,
      this.sliderOutterColor,
      this.onDragStart,
      this.onDragUpdate,
      this.onDragEnd,
      this.canDrag = true,
      this.playPoints = const [],
      this.onPointClick,
      GlobalKey<VideoSliderState>? key})
      : super(key: key) {
    double range = (max - min);
    if (range <= 0) {
      controller = VideoSliderController(1, bufferedProgress: 1);
    } else {
      double currentProgress = remainTwoFixed(value / range);
      double? bufferedProgress = bufferedValue != null ? remainTwoFixed(bufferedValue! / range) : null;
      controller = VideoSliderController(currentProgress, bufferedProgress: bufferedProgress);
    }
  }

  /// remain two fixed,avoid double precision problem
  double remainTwoFixed(double value) {
    int valueInt = (value * 100).toInt();
    return valueInt / 100;
  }

  @override
  State<StatefulWidget> createState() => VideoSliderState();
}

class VideoSliderState extends State<VideoSlider> {
  late _VideoSliderShaders shaders;
  final defaultHeight = 10.0;
  final defaultRadius = 5.0;
  bool isDraging = false;

  @override
  void initState() {
    super.initState();
    shaders = _VideoSliderShaders(
        backgroundColor: widget.inactiveColor,
        progressColor: widget.activeColor,
        dragSliderColor: widget.sliderColor,
        bufferedColor: widget.bufferedColor,
        drawSliderOverlayColor: widget.sliderOutterColor);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double height = widget.progressHeight ?? defaultHeight;
    double radius = widget.sliderRadius ?? defaultRadius;
    double overlayRadius = widget.sliderOutterRadius ?? radius * 3;
    double leftPadding = overlayRadius;
    double rightPadding = overlayRadius;
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (widget.canDrag!) {
          isDraging = true;
          widget.onDragStart?.call();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (widget.canDrag!) {
          isDraging = true;
          _seekToPosition(details.globalPosition);
          widget.onDragUpdate?.call(widget.controller.progress);
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (widget.canDrag!) {
          isDraging = false;
          widget.onDragEnd?.call(widget.controller.progress);
        }
      },
      onHorizontalDragCancel: () {
        if (widget.canDrag! && isDraging) {
          isDraging = false;
          widget.onDragEnd?.call(widget.controller.progress);
        }
      },
      onVerticalDragCancel: () {
        if (widget.canDrag! && isDraging) {
          isDraging = false;
          widget.onDragEnd?.call(widget.controller.progress);
        }
      },
      onTapUp: (TapUpDetails details) {
        if (widget.canDrag! && !isDraging) {
          List<SliderPoint> tmp = widget.playPoints ?? [];
          for (int i = 0; i < tmp.length; i++) {
            SliderPoint point = tmp[i];
            final box = context.findRenderObject()! as RenderBox;
            final Offset tapPos = box.globalToLocal(details.globalPosition);
            double width = box.size.width;
            double pointStart = width * point.progress;
            double clickRadius = radius * 3;
            if (tapPos.dx > pointStart - clickRadius && tapPos.dx < pointStart + clickRadius) {
              widget.onPointClick?.call(pointStart, i);
              return;
            }
          }
          _seekToPosition(details.globalPosition);
          widget.onDragEnd?.call(widget.controller.progress);
        }
      },
      onTapCancel: () {
        if (widget.canDrag!) {
          isDraging = false;
          widget.onDragEnd?.call(widget.controller.progress);
        }
      },
      child: Center(
        child: Container(
          width: size.width,
          height: max(height, 2 * radius),
          child: CustomPaint(
            painter: _VideoSliderPainter(
                shaders: shaders,
                progressHeight: height,
                sliderRadius: radius,
                isDraging: isDraging,
                percent: widget.controller.progress,
                bufferedPercent: widget.controller.bufferedProgress,
                leftPadding: leftPadding,
                rightPadding: rightPadding,
                pointList: widget.playPoints ?? [],
                sliderOverlayRadius: overlayRadius),
          ),
        ),
      ),
    );
  }

  double _getProgressByPosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    double progress = widget.controller.progress;
    progress = tapPos.dx / box.size.width;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    return progress;
  }

  void _seekToPosition(Offset globalPosition) {
    double progress = _getProgressByPosition(globalPosition);
    setState(() {
      widget.controller.progress = progress;
    });
  }
}

class _VideoSliderPainter extends CustomPainter {
  final _VideoSliderShaders shaders;
  final double progressHeight;
  final double sliderRadius;
  double sliderOverlayRadius;
  final double percent; // must range in 0.0 ~ 1.0
  final double? bufferedPercent; // must range in 0.0 ~ 1.0
  final bool isDraging;
  final double leftPadding;
  final double rightPadding;
  final List<SliderPoint> pointList;

  _VideoSliderPainter(
      {required this.shaders,
      required this.progressHeight,
      required this.sliderRadius,
      required this.percent,
      required this.isDraging,
      required this.sliderOverlayRadius,
      required this.leftPadding,
      required this.rightPadding,
      required this.pointList,
      this.bufferedPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final baseVerticalOffset = size.height / 2 - progressHeight / 2;
    final start = leftPadding;
    final end = size.width - rightPadding;
    final width = size.width - leftPadding - rightPadding;

    // draw background
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromPoints(Offset(start, baseVerticalOffset), Offset(end, baseVerticalOffset + progressHeight)),
            Radius.circular(sliderRadius)),
        shaders.backgroundPaint);

    // draw bufferdProgress
    if (null != bufferedPercent) {
      _checkRange(bufferedPercent!);
      final double bPercent = bufferedPercent!;
      double bufferedEndless = start + (width * bPercent);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromPoints(Offset(start, baseVerticalOffset), Offset(bufferedEndless, baseVerticalOffset + progressHeight)),
              Radius.circular(sliderRadius)),
          shaders.bufferedPaint);
    }

    // draw progress
    _checkRange(percent);
    final double ppercent = percent;
    double progressEndless = start + (width * ppercent);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromPoints(Offset(start, baseVerticalOffset), Offset(progressEndless, baseVerticalOffset + progressHeight)),
            Radius.circular(sliderRadius)),
        shaders.progressPaint);

    // draw point
    for (SliderPoint point in pointList) {
      double pointStart = start + (width * point.progress);
      shaders.pointPaint.color = point.pointColor;
      canvas.drawCircle(Offset(pointStart, size.height / 2), progressHeight, shaders.pointPaint);
    }

    // draw outer slider，only show when drag
    if (isDraging) {
      canvas.drawCircle(Offset(progressEndless, size.height / 2), sliderOverlayRadius, shaders.dragSliderOverlayPaint);
    }
    // draw inner slider
    canvas.drawCircle(Offset(progressEndless, size.height / 2), sliderRadius, shaders.dragSliderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _VideoSliderShaders {
  Paint backgroundPaint = Paint();
  Paint bufferedPaint = Paint();
  Paint progressPaint = Paint();
  Paint dragSliderPaint = Paint();
  Paint dragSliderOverlayPaint = Paint();
  Paint pointPaint = Paint();

  _VideoSliderShaders(
      {Color? backgroundColor, Color? progressColor, Color? dragSliderColor, Color? bufferedColor, Color? drawSliderOverlayColor}) {
    backgroundPaint.color = backgroundColor ?? Colors.grey;
    bufferedPaint.color = bufferedColor ?? Colors.blueGrey;
    progressPaint.color = progressColor ?? Colors.blueAccent;
    dragSliderPaint.color = dragSliderColor ?? Colors.blue;
    dragSliderOverlayPaint.color = drawSliderOverlayColor ?? Colors.white;
  }
}

class VideoSliderController {
  double progress;
  double? bufferedProgress;

  VideoSliderController(this.progress, {this.bufferedProgress});
}

void _checkRange(double value, {String? valueName}) {
  if (value < 0.0 || value > 1.0) {
    throw ArgumentError("${valueName ?? "value"} must range in 0.0 to 1.0,please check your param，current is $value");
  }
}
