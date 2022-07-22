// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.tencent.rtmp.downloader.ITXVodDownloadListener;
import com.tencent.rtmp.downloader.ITXVodPreloadListener;
import com.tencent.rtmp.downloader.TXVodDownloadDataSource;
import com.tencent.rtmp.downloader.TXVodDownloadManager;
import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;
import com.tencent.rtmp.downloader.TXVodPreloadManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * 下载管理，预下载、离线下载
 */
public class FTXDownloadManager implements MethodChannel.MethodCallHandler, ITXVodDownloadListener {
    private       FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;
    final private MethodChannel                      mMethodChannel;
    private final EventChannel                       mEventChannel;
    final private FTXPlayerEventSink                 mEventSink = new FTXPlayerEventSink();
    private       Handler                            mMainHandler;

    public FTXDownloadManager(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        mFlutterPluginBinding = flutterPluginBinding;
        mMainHandler = new Handler(mFlutterPluginBinding.getApplicationContext().getMainLooper());
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
        TXVodDownloadManager.getInstance().setListener(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("startPreLoad")) {
            String playUrl = call.argument("playUrl");
            int preloadSizeMB = call.argument("preloadSizeMB");
            int preferredResolution = call.argument("preferredResolution");
            final TXVodPreloadManager downloadManager =
                    TXVodPreloadManager.getInstance(mFlutterPluginBinding.getApplicationContext());
            final int retTaskID = downloadManager.startPreload(playUrl, preloadSizeMB, preferredResolution,
                    new ITXVodPreloadListener() {
                        @Override
                        public void onComplete(int taskID, String url) {
                            onCompleteEvent(taskID, url);
                        }

                        @Override
                        public void onError(int taskID, String url, int code, String msg) {
                            onErrorEvent(taskID, url, msg);
                        }
                    });
            result.success(retTaskID);
        } else if (call.method.equals("stopPreLoad")) {
            final TXVodPreloadManager downloadManager =
                    TXVodPreloadManager.getInstance(mFlutterPluginBinding.getApplicationContext());
            int taskId = call.argument("taskId");
            downloadManager.stopPreload(taskId);
            result.success(null);
        } else if (call.method.equals("startDownload")) {
            Integer quality = call.argument("quality");
            String videoUrl = call.argument("url");
            Integer appId = call.argument("appId");
            String fileId = call.argument("fileId");
            String pSign = call.argument("pSign");
            String userName = call.argument("userName");
            if (!TextUtils.isEmpty(videoUrl)) {
                TXVodDownloadManager.getInstance().startDownloadUrl(videoUrl, userName);
            } else if (null != appId && null != fileId) {
                TXVodDownloadDataSource dataSource = new TXVodDownloadDataSource(appId, fileId, optQuality(quality), pSign,
                        userName);
                TXVodDownloadManager.getInstance().startDownload(dataSource);
            }
            result.success(null);
        } else if (call.method.equals("stopDownload")) {
            Integer quality = call.argument("quality");
            String videoUrl = call.argument("url");
            Integer appId = call.argument("appId");
            String fileId = call.argument("fileId");
            TXVodDownloadMediaInfo mediaInfo = parseMediaInfoFromInfo(quality, videoUrl, appId, fileId);
            TXVodDownloadManager.getInstance().stopDownload(mediaInfo);
            result.success(null);
        } else if (call.method.equals("setDownloadHeaders")) {
            Map<String, String> headers = call.argument("headers");
            TXVodDownloadManager.getInstance().setHeaders(headers);
            result.success(null);
        } else if (call.method.equals("getDownloadList")) {
            List<TXVodDownloadMediaInfo> medias = TXVodDownloadManager.getInstance().getDownloadMediaInfoList();
            List<Map<String, Object>> mediaResults = new ArrayList<>();
            for (TXVodDownloadMediaInfo mediaInfo : medias) {
                mediaResults.add(buildMapFromDownloadMediaInfo(mediaInfo));
            }
            result.success(mediaResults);
        } else if (call.method.equals("getDownloadInfo")) {
            Integer quality = call.argument("quality");
            String videoUrl = call.argument("url");
            Integer appId = call.argument("appId");
            String fileId = call.argument("fileId");
            TXVodDownloadMediaInfo mediaInfo = parseMediaInfoFromInfo(quality, videoUrl, appId, fileId);
            result.success(buildMapFromDownloadMediaInfo(mediaInfo));
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

    private Map<String,Object> buildMapFromDownloadMediaInfo(TXVodDownloadMediaInfo mediaInfo) {
        Map<String, Object> resultMap = new HashMap<>();
        if (null != mediaInfo) {
            resultMap.put("playPath", mediaInfo.getPlayPath());
            resultMap.put("progress", mediaInfo.getProgress());
            resultMap.put("downloadState", CommonUtil.getDownloadEventByState(mediaInfo.getDownloadState()));
            resultMap.put("userName", mediaInfo.getUserName());
            resultMap.put("duration", mediaInfo.getDuration());
            resultMap.put("playableDuration", mediaInfo.getPlayableDuration());
            resultMap.put("size", mediaInfo.getSize());
            resultMap.put("downloadSize", mediaInfo.getDownloadSize());
            if (!TextUtils.isEmpty(mediaInfo.getUrl())) {
                resultMap.put("url", mediaInfo.getUrl());
            }
            if (mediaInfo.getDataSource() != null) {
                TXVodDownloadDataSource dataSource = mediaInfo.getDataSource();
                resultMap.put("appId", dataSource.getAppId());
                resultMap.put("fileId", dataSource.getFileId());
                resultMap.put("pSign", dataSource.getPSign());
                resultMap.put("quality", dataSource.getQuality());
                resultMap.put("token", dataSource.getToken());
            }
        }
        return resultMap;
    }

    private Bundle buildCommonDownloadBundle(TXVodDownloadMediaInfo mediaInfo) {
        Bundle bundle = new Bundle();
        bundle.putString("playPath", mediaInfo.getPlayPath());
        bundle.putFloat("progress", mediaInfo.getProgress());
        bundle.putInt("downloadState", CommonUtil.getDownloadEventByState(mediaInfo.getDownloadState()));
        bundle.putString("userName", mediaInfo.getUserName());
        bundle.putInt("duration", mediaInfo.getDuration());
        bundle.putInt("playableDuration", mediaInfo.getPlayableDuration());
        bundle.putInt("size", mediaInfo.getSize());
        bundle.putInt("downloadSize", mediaInfo.getDownloadSize());
        if (!TextUtils.isEmpty(mediaInfo.getUrl())) {
            bundle.putString("url", mediaInfo.getUrl());
        }
        if (null != mediaInfo.getDataSource()) {
            TXVodDownloadDataSource dataSource = mediaInfo.getDataSource();
            bundle.putInt("appId", dataSource.getAppId());
            bundle.putString("fileId", dataSource.getFileId());
            bundle.putString("pSign", dataSource.getPSign());
            bundle.putInt("quality", dataSource.getQuality());
            bundle.putString("token", dataSource.getToken());
        }
        return bundle;
    }

    private TXVodDownloadMediaInfo parseMediaInfoFromInfo(Integer quality, String url, Integer appId,
                                                          String fileId) {
        TXVodDownloadMediaInfo mediaInfo = null;
        if (!TextUtils.isEmpty(url)) {
            mediaInfo = TXVodDownloadManager.getInstance().getDownloadMediaInfo(url);
        } else if (null != appId && null != fileId) {
            mediaInfo = TXVodDownloadManager.getInstance().getDownloadMediaInfo(appId, fileId, optQuality(quality));
        }
        return mediaInfo;
    }

    private int optQuality(Integer quality) {
        return quality == null ? TXVodDownloadDataSource.QUALITY_FLU : quality;
    }

    @Override
    public void onDownloadStart(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(CommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_START, bundle));
    }


    @Override
    public void onDownloadProgress(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(CommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_PROGRESS, bundle));
    }

    @Override
    public void onDownloadStop(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(CommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_STOP, bundle));
    }

    @Override
    public void onDownloadFinish(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(CommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_FINISH, bundle));
    }

    @Override
    public void onDownloadError(TXVodDownloadMediaInfo txVodDownloadMediaInfo, int i, String s) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        bundle.putInt("errorCode", i);
        bundle.putString("errorMsg", s);
        sendSuccessEvent(CommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_ERROR, bundle));
    }

    /**
     * ijk遗留，暂时弃用
     */
    @Override
    public int hlsKeyVerify(TXVodDownloadMediaInfo txVodDownloadMediaInfo, String s, byte[] bytes) {
        return 0;
    }
}
