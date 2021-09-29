package com.example.super_player;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import com.tencent.liteav.demo.superplayer.SuperPlayerGlobalConfig;
import com.tencent.liteav.demo.superplayer.SuperPlayerModel;
import com.tencent.liteav.demo.superplayer.SuperPlayerVideoId;
import com.tencent.liteav.demo.superplayer.SuperPlayerView;
import com.tencent.rtmp.TXLiveBase;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class SuperPlatformPlayerView implements PlatformView, MethodChannel.MethodCallHandler, SuperPlayerView.OnSuperPlayerViewCallback {

    private SuperPlayerView mSuperPlayerView;
    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;
    private final MethodChannel mMethodChannel;
    private final EventChannel mEventChannel;
    private final FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();

    public SuperPlatformPlayerView(Context context, Map<String, Object> params, int viewId, FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        super();
        mSuperPlayerView = new SuperPlayerView(context);
        mSuperPlayerView.setPlayerViewCallback(this);
        mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/superPlayer/" + viewId);
        mMethodChannel.setMethodCallHandler(this);
        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/superPlayer/event/" + viewId);
        mEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mEventSink.setEventSinkProxy(eventSink);
            }

            @Override
            public void onCancel(Object o) {
                mEventSink.setEventSinkProxy(null);
            }
        });
//
//        if (params.containsKey("playerConfig")){
//            Map playerConfig = (Map) params.get("playerConfig");
//            SuperPlayerGlobalConfig prefs = SuperPlayerGlobalConfig.getInstance();
//            prefs.playShiftDomain = (String) playerConfig.get("playShiftDomain");
//            prefs.enableHWAcceleration = (boolean) playerConfig.get("hwAcceleration");
//            prefs.renderMode = (int) playerConfig.get("renderMode");
//        }
//
//        SuperPlayerModel model = new SuperPlayerModel();
//        if (params.containsKey("playerModel")) {
//            Map playerModel = (Map) params.get("playerModel");
//            model.url = (String) playerModel.get("videoURL");
//            model.appId = (int) playerModel.get("appId");
//            model.playDefaultIndex = (int) playerModel.get("defaultPlayIndex");
//            if (playerModel.containsKey("videoId")) {
//                Map videoIdMap = (Map) playerModel.get("videoId");
//                SuperPlayerVideoId videoId = new SuperPlayerVideoId();
//                videoId.fileId = (String) videoIdMap.get("videoId");
//                videoId.pSign = (String) videoIdMap.get("psign");
//                model.videoId = videoId;
//            }
//
//            if (playerModel.containsKey("multiVideoURLs")) {
//                List<SuperPlayerModel.SuperPlayerURL> multiURLs = new ArrayList<SuperPlayerModel.SuperPlayerURL>();
//                List<Map> mapURLs = (List<Map>) playerModel.get("multiVideoURLs");
//                for (Map e:mapURLs) {
//                    SuperPlayerModel.SuperPlayerURL url = new SuperPlayerModel.SuperPlayerURL();
//                    url.qualityName = (String) e.get("title");
//                    url.url = (String) e.get("url");
//                    multiURLs.add(url);
//                }
//                model.multiURLs = multiURLs;
//            }
//        }
//
//        mPlayerModel = model;
//        mSuperPlayerView.playWithModel(model);
    }


    @Override
    public void onStartFullScreenPlay() {
        mEventSink.success("onStartFullScreenPlay");
    }

    @Override
    public void onStopFullScreenPlay() {
        mEventSink.success("onStopFullScreenPlay");
    }

    @Override
    public void onClickFloatCloseBtn() {
        mEventSink.success("onClickFloatCloseBtn");
    }

    @Override
    public void onSuperPlayerBackAction() {
        mEventSink.success("onSuperPlayerBackAction");
    }

    @Override
    public void onStartFloatWindowPlay() {
        mEventSink.success("onStartFloatWindowPlay");
    }

    @Override
    public void onSuperPlayerDidStart() {
        mEventSink.success("onSuperPlayerDidStart");
    }

    @Override
    public void onSuperPlayerDidEnd() {
        mEventSink.success("onSuperPlayerDidEnd");
    }

    @Override
    public void onSuperPlayerError() {
        mEventSink.success("onSuperPlayerError");
    }

    @Override
    public View getView() {
        return mSuperPlayerView;
    }

    @Override
    public void dispose() {
        mSuperPlayerView.resetPlayer();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("reloadView")) {
//            String url = call.argument("url");
//            Integer appId = call.argument("appId");
//            String fileId = call.argument("fileId");
//            String psign = call.argument("psign");
//            reloadView(url, appId, fileId, psign);
            result.success(null);
        } else if (call.method.equals("play")) {
            Map playerModel = call.argument("playerModel");
            playWithModel(playerModel);
            result.success(null);
        } else if (call.method.equals("playConfig")) {
            Map playConfig = call.argument("config");
            setPlayConfig(playConfig);
            result.success(null);
        } else if(call.method.equals("disableGesture")) {
            Boolean enable = call.argument("enable");
            disableGesture(enable);
            result.success(null);
        } else if(call.method.equals("setIsAutoPlay")) {
            Boolean enable = call.argument("isAutoPlay");
            setIsAutoPlay(enable);
            result.success(null);
        } else if(call.method.equals("setStartTime")) {
            Double startTime = call.argument("startTime");
            setStartTime(startTime);
            result.success(null);
        } else if(call.method.equals("setLoop")) {
            Boolean enable = call.argument("loop");
            setLoop(enable);
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

//    public void reloadView(String url, Integer appId, String fileId, String psign) {
//        if (mPlayerModel == null) {
//            return;
//        }
//
//        if (url != null && !url.isEmpty()) {
//            mPlayerModel.videoId = null;
//            mPlayerModel.url = url;
//        }else if (appId > 0 && fileId != null && !fileId.isEmpty()) {
//            SuperPlayerVideoId videoId = new SuperPlayerVideoId();
//            mPlayerModel.appId = (int) appId;
//            videoId.fileId = fileId;
//            if (psign != null && !psign.isEmpty()) {
//                videoId.pSign = psign;
//            }
//            mPlayerModel.videoId = videoId;
//            mPlayerModel.url = null;
//        }
//
//        mSuperPlayerView.resetPlayer();
//        mSuperPlayerView.playWithModel(mPlayerModel);
//    }

    public void playWithModel(Map playerModel) {
        SuperPlayerModel model = new SuperPlayerModel();
        model.url = (String) playerModel.get("videoURL");
        model.appId = (int) playerModel.get("appId");
        if (model.appId > 0) {
            TXLiveBase.setAppID("" + model.appId);
        }
        model.playDefaultIndex = (int) playerModel.get("defaultPlayIndex");
        model.title = (String) playerModel.get("title");
        if (playerModel.containsKey("videoId")) {
            Map videoIdMap = (Map) playerModel.get("videoId");
            SuperPlayerVideoId videoId = new SuperPlayerVideoId();
            videoId.fileId = (String) videoIdMap.get("fileId");
            videoId.pSign = (String) videoIdMap.get("psign");
            model.videoId = videoId;
            model.url = null;
        }

        if (playerModel.containsKey("multiVideoURLs")) {
            List<SuperPlayerModel.SuperPlayerURL> multiURLs = new ArrayList<SuperPlayerModel.SuperPlayerURL>();
            List<Map> mapURLs = (List<Map>) playerModel.get("multiVideoURLs");
            for (Map e:mapURLs) {
                SuperPlayerModel.SuperPlayerURL url = new SuperPlayerModel.SuperPlayerURL();
                url.qualityName = (String) e.get("title");
                url.url = (String) e.get("url");
                multiURLs.add(url);
            }
            model.multiURLs = multiURLs;
        }

        mSuperPlayerView.resetPlayer();
        mSuperPlayerView.playWithModel(model);
    }

    public void setPlayConfig(Map params) {
        SuperPlayerGlobalConfig prefs = SuperPlayerGlobalConfig.getInstance();
        prefs.playShiftDomain = (String) params.get("playShiftDomain");
        prefs.enableHWAcceleration = (boolean) params.get("hwAcceleration");
        prefs.renderMode = (int) params.get("renderMode");
    }

    public void setIsAutoPlay(boolean b) {
        mSuperPlayerView.setIsAutoPlay(b);
    }

    public void setStartTime(double startTime) {
        mSuperPlayerView.setStartTime(startTime);
    }

    /**
     * 关闭所有手势
     * @param flag true为关闭手势，false为开启手势
     */
    public void disableGesture(boolean flag) {
        mSuperPlayerView.disableGesture(flag);
    }

    public void setLoop(boolean b) {
        mSuperPlayerView.setLoop(b);
    }
}
