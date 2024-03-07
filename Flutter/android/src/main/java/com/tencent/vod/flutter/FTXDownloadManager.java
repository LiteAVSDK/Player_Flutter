// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.tencent.rtmp.TXPlayInfoParams;
import com.tencent.rtmp.downloader.ITXVodDownloadListener;
import com.tencent.rtmp.downloader.ITXVodFilePreloadListener;
import com.tencent.rtmp.downloader.ITXVodPreloadListener;
import com.tencent.rtmp.downloader.TXVodDownloadDataSource;
import com.tencent.rtmp.downloader.TXVodDownloadManager;
import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;
import com.tencent.rtmp.downloader.TXVodPreloadManager;
import com.tencent.vod.flutter.messages.FtxMessages;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.MapMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PreLoadMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXDownloadListMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterDownloadApi;
import com.tencent.vod.flutter.messages.FtxMessages.TXVodDownloadMediaMsg;
import com.tencent.vod.flutter.tools.TXCommonUtil;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Download management, pre-download, and offline download.
 *
 * 下载管理，预下载、离线下载
 */
public class FTXDownloadManager implements ITXVodDownloadListener, TXFlutterDownloadApi {

    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;
    private final EventChannel mEventChannel;
    private final FTXPlayerEventSink mEventSink = new FTXPlayerEventSink();
    private final Handler mMainHandler;

    private ExecutorService mPreloadPool = Executors.newCachedThreadPool();

    /**
     * Video download management.
     *
     * 视频下载管理
     */
    public FTXDownloadManager(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        mFlutterPluginBinding = flutterPluginBinding;
        mMainHandler = new Handler(mFlutterPluginBinding.getApplicationContext().getMainLooper());

        TXFlutterDownloadApi.setup(mFlutterPluginBinding.getBinaryMessenger(), this);

        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
                "cloud.tencent.com/txvodplayer/download/event");
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

    private void onStartEvent(long tmpTaskId, int taskId, String fileId, String url, Bundle params) {
        Bundle bundle = new Bundle();
        bundle.putLong("tmpTaskId", tmpTaskId);
        bundle.putInt("taskId", taskId);
        bundle.putString("fileId", fileId);
        bundle.putString("url", url);
        Map<String, Object> result = TXCommonUtil.getParams(FTXEvent.EVENT_PREDOWNLOAD_ON_START, bundle);
        result.put("params", TXCommonUtil.transToMap(params));
        sendSuccessEvent(result);
    }

    private void onCompleteEvent(int taskId, String url) {
        Bundle bundle = new Bundle();
        bundle.putInt("taskId", taskId);
        bundle.putString("url", url);
        sendSuccessEvent(TXCommonUtil.getParams(FTXEvent.EVENT_PREDOWNLOAD_ON_COMPLETE, bundle));
    }

    private void onErrorEvent(long tmpTaskId, int taskId, String url, int code, String msg) {
        Bundle bundle = new Bundle();
        if (tmpTaskId >= 0) {
            bundle.putLong("tmpTaskId", tmpTaskId);
        }
        bundle.putInt("taskId", taskId);
        bundle.putInt("code", code);
        bundle.putString("url", url);
        bundle.putString("msg", msg);
        sendSuccessEvent(TXCommonUtil.getParams(FTXEvent.EVENT_PREDOWNLOAD_ON_ERROR, bundle));
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
        mEventChannel.setStreamHandler(null);
        TXVodDownloadManager.getInstance().setListener(null);
    }

    private TXVodDownloadMediaMsg buildMsgFromDownloadInfo(TXVodDownloadMediaInfo mediaInfo) {
        TXVodDownloadMediaMsg msg = new TXVodDownloadMediaMsg();
        if (null != mediaInfo) {
            msg.setPlayPath(mediaInfo.getPlayPath());
            msg.setDownloadState((long) TXCommonUtil.getDownloadEventByState(mediaInfo.getDownloadState()));
            msg.setUserName(mediaInfo.getUserName());
            msg.setDuration((long) mediaInfo.getDuration());
            msg.setPlayableDuration((long) mediaInfo.getPlayableDuration());
            msg.setSize(mediaInfo.getSize());
            msg.setDownloadSize(mediaInfo.getDownloadSize());
            if (!TextUtils.isEmpty(mediaInfo.getUrl())) {
                msg.setUrl(mediaInfo.getUrl());
            }

            BigDecimal progressDec = BigDecimal.valueOf(mediaInfo.getProgress());
            msg.setProgress(progressDec.doubleValue());
            if (null != mediaInfo.getDataSource()) {
                TXVodDownloadDataSource dataSource = mediaInfo.getDataSource();
                msg.setAppId((long) dataSource.getAppId());
                msg.setFileId(dataSource.getFileId());
                msg.setPSign(dataSource.getPSign());
                msg.setQuality((long) dataSource.getQuality());
                msg.setToken(dataSource.getToken());
            }
            msg.setSpeed((long) mediaInfo.getSpeed());
            msg.setIsResourceBroken(mediaInfo.isResourceBroken());
        }
        return msg;
    }

    private TXVodDownloadMediaInfo getDownloadInfoFromMsg(TXVodDownloadMediaMsg msg) {
        Integer quality = null != msg.getQuality() ? msg.getQuality().intValue() : 0;
        String videoUrl = msg.getUrl();
        Integer appId = null != msg.getAppId() ? msg.getAppId().intValue() : null;
        String fileId = msg.getFileId();
        String pSign = msg.getPSign();
        String userName = msg.getUserName();
        return parseMediaInfoFromInfo(quality, videoUrl, appId, fileId, userName);
    }

    private Bundle buildCommonDownloadBundle(TXVodDownloadMediaInfo mediaInfo) {
        Bundle bundle = new Bundle();
        bundle.putString("playPath", mediaInfo.getPlayPath());
        bundle.putFloat("progress", mediaInfo.getProgress());
        bundle.putInt("downloadState", TXCommonUtil.getDownloadEventByState(mediaInfo.getDownloadState()));
        bundle.putString("userName", mediaInfo.getUserName());
        bundle.putInt("duration", mediaInfo.getDuration());
        bundle.putInt("playableDuration", mediaInfo.getPlayableDuration());
        bundle.putLong("size", mediaInfo.getSize());
        bundle.putLong("downloadSize", mediaInfo.getDownloadSize());
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
        bundle.putInt("speed", mediaInfo.getSpeed());
        bundle.putBoolean("isResourceBroken", mediaInfo.isResourceBroken());
        return bundle;
    }

    private TXVodDownloadMediaInfo parseMediaInfoFromInfo(Integer quality, String url, Integer appId,
                                                          String fileId, String userName) {
        TXVodDownloadMediaInfo mediaInfo = null;
        if (null == userName) {
            userName = "default";
        }
        if (null != appId && null != fileId) {
            mediaInfo = TXVodDownloadManager.getInstance()
                    .getDownloadMediaInfo(appId, fileId, optQuality(quality), userName);
        } else if (!TextUtils.isEmpty(url)) {
            mediaInfo = TXVodDownloadManager.getInstance().getDownloadMediaInfo(url, -1L, userName);
            // To prevent the issue where downloading from the URL does not support specifying the userName
            if (null == mediaInfo) {
                mediaInfo = parseMediaInfoFromInfoByAll(quality, url, appId, fileId, userName);
            }
        }
        return mediaInfo;
    }

    private TXVodDownloadMediaInfo parseMediaInfoFromInfoByAll(Integer quality, String url, Integer appId,
                                                               String fileId, String userName) {
        boolean isFileIdInfo = null != appId && null != fileId;
        boolean isUrlInfo = !TextUtils.isEmpty(url);
        List<TXVodDownloadMediaInfo> mediaInfoList = TXVodDownloadManager.getInstance().getDownloadMediaInfoList();
        if (null != mediaInfoList && (isFileIdInfo || isUrlInfo)) {
            for (TXVodDownloadMediaInfo mediaInfo : mediaInfoList) {
                if (TextUtils.equals(userName, mediaInfo.getUserName())) {
                    if (isFileIdInfo) {
                        TXVodDownloadDataSource dataSource = mediaInfo.getDataSource();
                        if (null != dataSource) {
                            if (dataSource.getAppId() == appId && TextUtils.equals(dataSource.getFileId(), fileId)
                                    && optQuality(quality) == dataSource.getQuality()) {
                                return mediaInfo;
                            }
                        }
                    } else if (TextUtils.equals(url, mediaInfo.getUrl())) {
                        return mediaInfo;
                    }
                }
            }
        }
        return null;
    }

    private int optQuality(Integer quality) {
        return quality == null ? TXVodDownloadDataSource.QUALITY_UNK : quality;
    }

    @Override
    public void onDownloadStart(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(TXCommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_START, bundle));
    }


    @Override
    public void onDownloadProgress(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(TXCommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_PROGRESS, bundle));
    }

    @Override
    public void onDownloadStop(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(TXCommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_STOP, bundle));
    }

    @Override
    public void onDownloadFinish(TXVodDownloadMediaInfo txVodDownloadMediaInfo) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        sendSuccessEvent(TXCommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_FINISH, bundle));
    }

    @Override
    public void onDownloadError(TXVodDownloadMediaInfo txVodDownloadMediaInfo, int i, String s) {
        Bundle bundle = buildCommonDownloadBundle(txVodDownloadMediaInfo);
        bundle.putInt("errorCode", i);
        bundle.putString("errorMsg", s);
        sendSuccessEvent(TXCommonUtil.getParams(FTXEvent.EVENT_DOWNLOAD_ERROR, bundle));
    }

    /**
     * ijk legacy, temporarily abandoned.
     *
     * ijk遗留，暂时弃用
     */
    @Override
    public int hlsKeyVerify(TXVodDownloadMediaInfo txVodDownloadMediaInfo, String s, byte[] bytes) {
        return 0;
    }

    @NonNull
    @Override
    public IntMsg startPreLoad(@NonNull PreLoadMsg msg) {
        String playUrl = msg.getPlayUrl();
        float preloadSizeMB = msg.getPreloadSizeMB() != null ? msg.getPreloadSizeMB().floatValue() : 0;
        long preferredResolution = msg.getPreferredResolution() != null ? msg.getPreferredResolution() : 0;
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
                        onErrorEvent(-1, taskID, url, code, msg);
                    }
                });
        IntMsg res = new IntMsg();
        res.setValue((long) retTaskID);
        return res;
    }

    @NonNull
    @Override
    public void startPreLoadByParams(@NonNull FtxMessages.PreLoadInfoMsg msg) {
        mPreloadPool.execute(new Runnable() {
            @Override
            public void run() {
                final boolean isUrlPreload = !TextUtils.isEmpty(msg.getPlayUrl());
                TXPlayInfoParams txPlayInfoParams;
                if (isUrlPreload) {
                    txPlayInfoParams = new TXPlayInfoParams(msg.getPlayUrl());
                } else {
                    int appId = msg.getAppId() != null ? msg.getAppId().intValue() : 0;
                    txPlayInfoParams = new TXPlayInfoParams(appId, msg.getFileId(), msg.getPSign());
                }
                final TXVodPreloadManager downloadManager =
                        TXVodPreloadManager.getInstance(mFlutterPluginBinding.getApplicationContext());
                float preloadSizeMB = msg.getPreloadSizeMB() != null ? msg.getPreloadSizeMB().floatValue() : 0;
                final long tmpTaskId = msg.getTmpPreloadTaskId() != null ? msg.getTmpPreloadTaskId() : -1;
                long preferredResolution = msg.getPreferredResolution() != null ? msg.getPreferredResolution() : 0;
                int retTaskID = downloadManager.startPreload(txPlayInfoParams, preloadSizeMB, preferredResolution,
                        new ITXVodFilePreloadListener() {

                    @Override
                    public void onStart(int taskID, String fileId, String url, Bundle bundle) {
                        if (tmpTaskId >= 0) {
                            onStartEvent(tmpTaskId, taskID, fileId, url, bundle);
                        }
                    }

                    @Override
                    public void onComplete(int taskID, String url) {
                        onCompleteEvent(taskID, url);
                    }

                    @Override
                    public void onError(int taskID, String url, int code, String msg) {
                        onErrorEvent(tmpTaskId, taskID, url, code, msg);
                    }
                });
                if (isUrlPreload && tmpTaskId >= 0) {
                    onStartEvent(tmpTaskId, retTaskID, msg.getFileId(), msg.getPlayUrl(), new Bundle());
                }
            }
        });
    }

    @Override
    public void stopPreLoad(@NonNull IntMsg msg) {
        if (null != msg.getValue()) {
            final TXVodPreloadManager downloadManager =
                    TXVodPreloadManager.getInstance(mFlutterPluginBinding.getApplicationContext());
            downloadManager.stopPreload(msg.getValue().intValue());
        }
    }

    @Override
    public void startDownload(@NonNull TXVodDownloadMediaMsg msg) {
        Integer quality = null != msg.getQuality() ? msg.getQuality().intValue() : 0;
        String videoUrl = msg.getUrl();
        Integer appId = null != msg.getAppId() ? msg.getAppId().intValue() : null;
        String fileId = msg.getFileId();
        String pSign = msg.getPSign();
        String userName = msg.getUserName();
        if (!TextUtils.isEmpty(videoUrl)) {
            TXVodDownloadManager.getInstance().startDownloadUrl(videoUrl, userName);
        } else if (null != appId && null != fileId) {
            TXVodDownloadDataSource dataSource =
                    new TXVodDownloadDataSource(appId, fileId, optQuality(quality), pSign, userName);
            TXVodDownloadManager.getInstance().startDownload(dataSource);
        }
    }

    @Override
    public void resumeDownload(@NonNull TXVodDownloadMediaMsg msg) {
        TXVodDownloadMediaInfo mediaInfo = getDownloadInfoFromMsg(msg);
        if (null != mediaInfo) {
            TXVodDownloadDataSource dataSource = mediaInfo.getDataSource();
            if (dataSource != null) {
                TXVodDownloadManager.getInstance().startDownload(dataSource);
            } else {
                TXVodDownloadManager.getInstance().startDownloadUrl(mediaInfo.getUrl(), mediaInfo.getUserName());
            }
        }
    }

    @Override
    public void stopDownload(@NonNull TXVodDownloadMediaMsg msg) {
        TXVodDownloadMediaInfo mediaInfo = getDownloadInfoFromMsg(msg);
        TXVodDownloadManager.getInstance().stopDownload(mediaInfo);
    }

    @Override
    public void setDownloadHeaders(@NonNull MapMsg headers) {
        TXVodDownloadManager.getInstance().setHeaders(headers.getMap());
    }

    @NonNull
    @Override
    public TXDownloadListMsg getDownloadList() {
        List<TXVodDownloadMediaInfo> medias = TXVodDownloadManager.getInstance().getDownloadMediaInfoList();
        List<TXVodDownloadMediaMsg> mediaResults = new ArrayList<>();
        for (TXVodDownloadMediaInfo mediaInfo : medias) {
            mediaResults.add(buildMsgFromDownloadInfo(mediaInfo));
        }
        TXDownloadListMsg res = new TXDownloadListMsg();
        res.setInfoList(mediaResults);
        return res;
    }

    @NonNull
    @Override
    public TXVodDownloadMediaMsg getDownloadInfo(@NonNull TXVodDownloadMediaMsg msg) {
        TXVodDownloadMediaInfo mediaInfo = getDownloadInfoFromMsg(msg);
        return buildMsgFromDownloadInfo(mediaInfo);
    }

    @NonNull
    @Override
    public BoolMsg deleteDownloadMediaInfo(@NonNull TXVodDownloadMediaMsg msg) {
        TXVodDownloadMediaInfo mediaInfo = getDownloadInfoFromMsg(msg);
        boolean deleteResult = false;
        if (mediaInfo != null) {
            deleteResult = TXVodDownloadManager.getInstance().deleteDownloadMediaInfo(mediaInfo);
        }
        BoolMsg res = new BoolMsg();
        res.setValue(deleteResult);
        return res;
    }
}
