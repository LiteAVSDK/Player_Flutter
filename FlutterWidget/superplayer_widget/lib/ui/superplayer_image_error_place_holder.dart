// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class ImageWithGrayBackground extends StatelessWidget {

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;

  ImageWithGrayBackground(String src,
  {
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center
  }) : imageUrl = src;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color.fromRGBO(211, 211, 211, 0.5)), // 灰色背景
      child: Image.network(
        imageUrl,
        width: this.width,
        height: this.height,
        fit: this.fit,
        alignment: this.alignment,
        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Center(
            child: Text(
                'image load failed',
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        },
      ),
    );
  }
}