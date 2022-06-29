// Copyright (c) 2022 Tencent. All rights reserved.
package com.tencent.vod.flutter;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

/**
 * 音频管理
 */
public class FTXAudioManager {

    private final static String TAG = "FTXAudioManager";

    private AudioManager                            mAudioManager;
    private AudioFocusRequest                       mFocusRequest;
    private AudioAttributes                         mAudioAttributes;
    private int                                     volumeUIFlag = 0;
    private List<AudioFocusChangeListener>          mAudioFocusListeners = new ArrayList<>();

    AudioManager.OnAudioFocusChangeListener afChangeListener =
            new AudioManager.OnAudioFocusChangeListener() {
                public void onAudioFocusChange(int focusChange) {
                    if (focusChange == AudioManager.AUDIOFOCUS_LOSS) {
                        //长时间丢失焦点,当其他应用申请的焦点为AUDIOFOCUS_GAIN时，会触发此回调事件
                        //例如播放QQ音乐，网易云音乐等
                        //此时应当暂停音频并释放音频相关的资源。
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                        //短暂性丢失焦点，当其他应用申请AUDIOFOCUS_GAIN_TRANSIENT或AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE时，会触发此回调事件
                        //例如播放短视频，拨打电话等。
                        //通常需要暂停音乐播放
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) {
                        //短暂性丢失焦点并作降音处理，当其他应用申请AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK时，会触发此回调事件
                        //通常需要降低音量
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
                        //当其他应用申请焦点之后又释放焦点会触发此回调
                        //可重新播放音乐
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPlay();
                            }
                        });
                    }
                }
            };

    public FTXAudioManager(Context context) {
        mAudioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
    }

    public void setVolumeUIVisible(boolean visible) {
        if (visible) {
            volumeUIFlag = AudioManager.FLAG_SHOW_UI;
        } else {
            volumeUIFlag = 0;
        }
    }

    public float getSystemCurrentVolume() {
        int curVolume = mAudioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        int maxVolume = mAudioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
        return (float) curVolume / maxVolume;
    }

    public void setSystemVolume(Double volume) {
        if (null != volume) {
            if (volume < 0) {
                volume = 0d;
            }
            if (volume > 1) {
                volume = 1d;
            }
            int maxVolume = mAudioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
            int newVolume = (int) (volume * maxVolume);
            mAudioManager.setStreamVolume(AudioManager.STREAM_MUSIC, newVolume, volumeUIFlag);
        }
    }


    public void abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (mFocusRequest != null) {
                mAudioManager.abandonAudioFocusRequest(mFocusRequest);
            }
        } else {
            if (afChangeListener != null) {
                mAudioManager.abandonAudioFocus(afChangeListener);
            }
        }
    }

    public void requestAudioFocus() {
        int result;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (mFocusRequest == null) {
                if (mAudioAttributes == null) {
                    mAudioAttributes = new AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build();
                }
                mFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(mAudioAttributes)
                        .setAcceptsDelayedFocusGain(true)
                        .setOnAudioFocusChangeListener(afChangeListener)
                        .build();
            }
            result = mAudioManager.requestAudioFocus(mFocusRequest);
        } else {
            result = mAudioManager.requestAudioFocus(afChangeListener, AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN);
        }
        Log.e(TAG, "requestAudioFocus result:" + result);
    }

    public void addAudioFocusChangedListener(AudioFocusChangeListener listener) {
        if(!mAudioFocusListeners.contains(listener)) {
            mAudioFocusListeners.add(listener);
        }
    }

    public void removeAudioFocusChangedListener(AudioFocusChangeListener listener) {
        mAudioFocusListeners.remove(listener);
    }

    void onAudioFocusPause() {
        for(AudioFocusChangeListener listener : mAudioFocusListeners) {
            listener.onAudioFocusPause();
        }
    }

    void onAudioFocusPlay() {
        for(AudioFocusChangeListener listener : mAudioFocusListeners) {
            listener.onAudioFocusPlay();
        }
    }

    interface AudioFocusChangeListener {
        void onAudioFocusPause();
        void onAudioFocusPlay();
    }
}
