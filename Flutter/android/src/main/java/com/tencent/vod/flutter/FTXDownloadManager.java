package com.tencent.vod.flutter;

import android.os.Bundle;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.tencent.rtmp.downloader.ITXVodPreloadListener;
import com.tencent.rtmp.downloader.TXVodPreloadManager;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FTXDownloadManager implements MethodChannel.MethodCallHandler{
    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;
    final private MethodChannel mMethodChannel;
    private final EventChannel mEventChannel;
    final private FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();
    private Handler mMainHandler;

    public FTXDownloadManager(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        mFlutterPluginBinding = flutterPluginBinding;
        mMainHandler= new Handler(mFlutterPluginBinding.getApplicationContext().getMainLooper());
        mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txvodplayer/download/api");
        mMethodChannel.setMethodCallHandler(this);

        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "cloud.tencent.com/txvodplayer/download/event");
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
    }
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("startPreLoad")) {
            String playUrl = call.argument("playUrl");
            int preloadSizeMB = call.argument("preloadSizeMB");
            int preferredResolution = call.argument("preferredResolution");
            final TXVodPreloadManager downloadManager = TXVodPreloadManager.getInstance(mFlutterPluginBinding.getApplicationContext());
            final int retTaskID = downloadManager.startPreload(playUrl, preloadSizeMB, preferredResolution, new ITXVodPreloadListener() {
                @Override
                public void onComplete(int taskID, String url) {
                    onCompleteEvent(taskID,url);
                }

                @Override
                public void onError(int taskID, String url, int code, String msg) {
                    onErrorEvent(taskID, url, msg);
                }

            });
            result.success(retTaskID);
        } else if (call.method.equals("stopPreLoad")) {
            final TXVodPreloadManager downloadManager = TXVodPreloadManager.getInstance(mFlutterPluginBinding.getApplicationContext());
            int taskId = call.argument("taskId");
            downloadManager.stopPreload(taskId);
            result.success(null);
        }
    }

    private void onCompleteEvent(int taskId, String url) {
        Bundle bundle = new Bundle();
        bundle.putInt("taskId", taskId);
        bundle.putString("url", url);
        sendSuccessEvent(CommonUtil.getParams(FTXEvent.EVENT_PREDOWNLOAD_ON_COMPLETE, bundle));
    }

    private void onErrorEvent(int taskId, String url, String msg) {
        Bundle bundle = new Bundle();
        bundle.putInt("taskId", taskId);
        bundle.putString("url", url);
        bundle.putString("msg", msg);
        sendSuccessEvent(CommonUtil.getParams(FTXEvent.EVENT_PREDOWNLOAD_ON_ERROR, bundle));
    }

    private void sendSuccessEvent(final Object event) {
        mMainHandler.post(new Runnable() {
            @Override
            public void run() {
                mEventSink.success(event);
            }
        });
    }


    public void destroy() {
        mMethodChannel.setMethodCallHandler(null);
        mEventChannel.setStreamHandler(null);
    }
}
