// @dart = 2.7
part of SuperPlayer;

class SuperPlayerViewModel {
  int appId = 0;
  String videoURL = "";
  List<SuperPlayerUrl> multiVideoURLs = [];
  int defaultPlayIndex = 0;
  SuperPlayerVideoId videoId;
  String title = "";
  String coverUrl = "";//flutter页面显示，转json时不需要传给播放器
  int duration = 0;//flutter页面显示，转json时不需要传给播放器

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    List<Map> videoURLs = [];
    for (var url in multiVideoURLs) {
      videoURLs.add({
        "title":url.title,
        "url":url.url,
      });
    }
    json["multiVideoURLs"] = videoURLs;
    json["appId"] = appId;
    json["title"] = title;
    json["videoURL"] = videoURL;
    json["defaultPlayIndex"] = defaultPlayIndex;
    if (videoId != null && videoId.fileId.isNotEmpty) {
      json["videoId"] = {
        "fileId":videoId.fileId,
        "psign":videoId.psign
      };
    }

    return json;
  }
}