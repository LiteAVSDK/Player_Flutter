import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_player/super_player.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_super_player');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SuperPlayerPlugin.instance;
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await SuperPlayerPlugin.platformVersion, '42');
  });

  test('TXVodPreDownlaodController_startPreLoad', () async {
    await SuperPlayerPlugin.setGlobalCacheFolderPath("tx");
    await SuperPlayerPlugin.setGlobalMaxCacheSize(200);
    String _url =
        "http://1400329073.vod2.myqcloud.com/d62d88a7vodtranscq1400329073/59c68fe75285890800381567412/adp.10.m3u8";
    int taskId = await TXVodDownloadController.instance.startPreLoad(_url, 20, 720*1080,
        onCompleteListener:(int taskId,String url) {
          print('taskID=${taskId} ,url=${url}');
        }, onErrorListener: (int taskId, String url, int code, String msg) {
          print('taskID=${taskId} ,url=${url}, code=${code} , msg=${msg}');
        } );
    expect(taskId != -1 , true);
  });
}
