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
 * Audio management.
 */
public class FTXAudioManager {

    private static final String TAG = "FTXAudioManager";

    private AudioManager                            mAudioManager;
    private AudioFocusRequest                       mFocusRequest;
    private AudioAttributes                         mAudioAttributes;
    private int                                     volumeUIFlag = 0;
    private List<AudioFocusChangeListener>          mAudioFocusListeners = new ArrayList<>();

    AudioManager.OnAudioFocusChangeListener afChangeListener =
            new AudioManager.OnAudioFocusChangeListener() {
                public void onAudioFocusChange(int focusChange) {
                    if (focusChange == AudioManager.AUDIOFOCUS_LOSS) {
                        // When the focus is lost for a long time, this callback event will be triggered when
                        // the focus requested by other applications is AUDIOFOCUS_GAIN.
                        // For example, playing QQ music, Netease Cloud Music, etc.
                        // At this time, audio should be paused and audio-related resources should be released.
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                        // When the focus is lost briefly, this callback event will be triggered when other
                        // applications request AUDIOFOCUS_GAIN_TRANSIENT or AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE.
                        // For example, playing short videos, making phone calls, etc.
                        // Usually need to pause music playback.
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) {
                        // When the focus is lost briefly and ducking is performed, this callback event will be
                        // triggered when other applications request AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK.
                        // Usually need to lower the volume.
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                onAudioFocusPause();
                            }
                        });
                    } else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
                        // This callback will be triggered when other applications request focus
                        // and then release focus.
                        // Music can be played again.
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

    /**
     * Request audio focus.
     *
     * 请求获取音频焦点
     */
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
        if (!mAudioFocusListeners.contains(listener)) {
            mAudioFocusListeners.add(listener);
        }
    }

    public void removeAudioFocusChangedListener(AudioFocusChangeListener listener) {
        mAudioFocusListeners.remove(listener);
    }

    void onAudioFocusPause() {
        for (AudioFocusChangeListener listener : mAudioFocusListeners) {
            listener.onAudioFocusPause();
        }
    }

    void onAudioFocusPlay() {
        for (AudioFocusChangeListener listener : mAudioFocusListeners) {
            listener.onAudioFocusPlay();
        }
    }

    interface AudioFocusChangeListener {
        void onAudioFocusPause();

        void onAudioFocusPlay();
    }
}
