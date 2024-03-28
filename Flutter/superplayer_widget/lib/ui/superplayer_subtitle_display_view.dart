part of demo_super_player_lib;

class SubtitleDisplayView extends StatefulWidget {
  final TXVodSubtitleData subtitleData;
  final TXSubtitleRenderModel? renderModel;
  final AlignmentGeometry alignment;

  SubtitleDisplayView(this.subtitleData, {
    this.alignment = Alignment.bottomCenter,
    this.renderModel
  });

  @override
  State<StatefulWidget> createState() {
    return _SubtitleDisplayViewState();
  }
}

class _SubtitleDisplayViewState extends State<SubtitleDisplayView> {
  @override
  Widget build(BuildContext context) {
    String subtitledDataStr = widget.subtitleData.subtitleData ?? "";

    int fontColorInt = widget.renderModel?.fontColor ??
        SubtitleController.defaultFontColor;
    Color fontColor = Color(fontColorInt);
    double fontSize = widget.renderModel?.fontSize ??
        SubtitleController.defaultFontSize;
    int outlineColorInt = widget.renderModel?.outlineColor ??
        SubtitleController.defaultOutlineColor;
    Color outlineColor = Color(outlineColorInt);
    double outlineWidth = widget.renderModel?.outlineWidth ??
        SubtitleController.defaultOutlineWidth;
    bool isBold = widget.renderModel?.isBondFontStyle ??
        SubtitleController.defaultFondBold == "1";

    return Align(
      alignment: widget.alignment,
      child: Stack(
        children: <Widget>[
          // Stroked text as border.
          Text(
            subtitledDataStr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = outlineWidth
                ..color = outlineColor,
            ),
          ),
          // Solid text as fill.
          Text(
            subtitledDataStr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: fontColor,
            ),
          ),
        ],
      ),);
  }
}
