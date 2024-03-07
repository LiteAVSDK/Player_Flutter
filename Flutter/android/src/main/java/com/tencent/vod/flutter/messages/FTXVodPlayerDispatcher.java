// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.messages;

import androidx.annotation.NonNull;
import com.tencent.vod.flutter.FTXBasePlayer;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.BoolPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.DoubleMsg;
import com.tencent.vod.flutter.messages.FtxMessages.DoublePlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.FTXVodPlayConfigPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.ListMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PipParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringListPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterVodPlayerApi;
import com.tencent.vod.flutter.messages.FtxMessages.TXPlayInfoParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.UInt8ListMsg;

/**
 * VOD event distribution.
 * 
 * 点播事件分发
 */
@SuppressWarnings("ConstantConditions")
public class FTXVodPlayerDispatcher implements FtxMessages.TXFlutterVodPlayerApi {

    final ITXPlayersBridge bridge;

    public FTXVodPlayerDispatcher(@NonNull ITXPlayersBridge dataBridge) {
        this.bridge = dataBridge;
    }

    TXFlutterVodPlayerApi getPlayer(Long playerID) {
        if (null != playerID) {
            FTXBasePlayer ftxBasePlayer = bridge.getPlayers().get(playerID.intValue());
            if (ftxBasePlayer instanceof FtxMessages.TXFlutterVodPlayerApi) {
                return (TXFlutterVodPlayerApi) ftxBasePlayer;
            }
        }
        return null;
    }

    @NonNull
    @Override
    public IntMsg initialize(@NonNull BoolPlayerMsg onlyAudio) {
        TXFlutterVodPlayerApi api = getPlayer(onlyAudio.getPlayerId());
        if (null != api) {
            return api.initialize(onlyAudio);
        }
        return null;
    }

    @NonNull
    @Override
    public BoolMsg startVodPlay(@NonNull StringPlayerMsg url) {
        TXFlutterVodPlayerApi api = getPlayer(url.getPlayerId());
        if (null != api) {
            return api.startVodPlay(url);
        }
        return null;
    }

    @Override
    public void startVodPlayWithParams(@NonNull TXPlayInfoParamsPlayerMsg params) {
        TXFlutterVodPlayerApi api = getPlayer(params.getPlayerId());
        if (null != api) {
            api.startVodPlayWithParams(params);
        }
    }

    @Override
    public void setAutoPlay(@NonNull BoolPlayerMsg isAutoPlay) {
        TXFlutterVodPlayerApi api = getPlayer(isAutoPlay.getPlayerId());
        if (null != api) {
            api.setAutoPlay(isAutoPlay);
        }
    }

    @NonNull
    @Override
    public BoolMsg stop(@NonNull BoolPlayerMsg isNeedClear) {
        TXFlutterVodPlayerApi api = getPlayer(isNeedClear.getPlayerId());
        if (null != api) {
            return api.stop(isNeedClear);
        }
        return null;
    }

    @NonNull
    @Override
    public BoolMsg isPlaying(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.isPlaying(playerMsg);
        }
        return null;
    }

    @Override
    public void pause(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            api.pause(playerMsg);
        }
    }

    @Override
    public void resume(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            api.resume(playerMsg);
        }
    }

    @Override
    public void setMute(@NonNull BoolPlayerMsg mute) {
        TXFlutterVodPlayerApi api = getPlayer(mute.getPlayerId());
        if (null != api) {
            api.setMute(mute);
        }
    }

    @Override
    public void setLoop(@NonNull BoolPlayerMsg loop) {
        TXFlutterVodPlayerApi api = getPlayer(loop.getPlayerId());
        if (null != api) {
            api.setLoop(loop);
        }
    }

    @Override
    public void seek(@NonNull DoublePlayerMsg progress) {
        TXFlutterVodPlayerApi api = getPlayer(progress.getPlayerId());
        if (null != api) {
            api.seek(progress);
        }
    }

    @Override
    public void setRate(@NonNull DoublePlayerMsg rate) {
        TXFlutterVodPlayerApi api = getPlayer(rate.getPlayerId());
        if (null != api) {
            api.setRate(rate);
        }
    }

    @NonNull
    @Override
    public ListMsg getSupportedBitrate(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getSupportedBitrate(playerMsg);
        }
        return null;
    }

    @NonNull
    @Override
    public IntMsg getBitrateIndex(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getBitrateIndex(playerMsg);
        }
        return null;
    }

    @Override
    public void setBitrateIndex(@NonNull IntPlayerMsg index) {
        TXFlutterVodPlayerApi api = getPlayer(index.getPlayerId());
        if (null != api) {
            api.setBitrateIndex(index);
        }
    }

    @Override
    public void setStartTime(@NonNull DoublePlayerMsg startTime) {
        TXFlutterVodPlayerApi api = getPlayer(startTime.getPlayerId());
        if (null != api) {
            api.setStartTime(startTime);
        }
    }

    @Override
    public void setAudioPlayOutVolume(@NonNull IntPlayerMsg volume) {
        TXFlutterVodPlayerApi api = getPlayer(volume.getPlayerId());
        if (null != api) {
            api.setAudioPlayOutVolume(volume);
        }
    }

    @NonNull
    @Override
    public BoolMsg setRequestAudioFocus(@NonNull BoolPlayerMsg focus) {
        TXFlutterVodPlayerApi api = getPlayer(focus.getPlayerId());
        if (null != api) {
            return api.setRequestAudioFocus(focus);
        }
        return null;
    }

    @Override
    public void setConfig(@NonNull FTXVodPlayConfigPlayerMsg config) {
        TXFlutterVodPlayerApi api = getPlayer(config.getPlayerId());
        if (null != api) {
            api.setConfig(config);
        }
    }

    @NonNull
    @Override
    public DoubleMsg getCurrentPlaybackTime(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getCurrentPlaybackTime(playerMsg);
        }
        return null;
    }

    @NonNull
    @Override
    public DoubleMsg getBufferDuration(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getBufferDuration(playerMsg);
        }
        return null;
    }

    @NonNull
    @Override
    public DoubleMsg getPlayableDuration(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getPlayableDuration(playerMsg);
        }
        return null;
    }

    @NonNull
    @Override
    public IntMsg getWidth(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getWidth(playerMsg);
        }
        return null;
    }

    @NonNull
    @Override
    public IntMsg getHeight(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getHeight(playerMsg);
        }
        return null;
    }

    @Override
    public void setToken(@NonNull StringPlayerMsg token) {
        TXFlutterVodPlayerApi api = getPlayer(token.getPlayerId());
        if (null != api) {
            api.setToken(token);
        }
    }

    @NonNull
    @Override
    public BoolMsg isLoop(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.isLoop(playerMsg);
        }
        return null;
    }

    @NonNull
    @Override
    public BoolMsg enableHardwareDecode(@NonNull BoolPlayerMsg enable) {
        TXFlutterVodPlayerApi api = getPlayer(enable.getPlayerId());
        if (null != api) {
            return api.enableHardwareDecode(enable);
        }
        return null;
    }

    @NonNull
    @Override
    public IntMsg enterPictureInPictureMode(@NonNull PipParamsPlayerMsg pipParamsMsg) {
        TXFlutterVodPlayerApi api = getPlayer(pipParamsMsg.getPlayerId());
        if (null != api) {
            return api.enterPictureInPictureMode(pipParamsMsg);
        }
        return null;
    }

    @Override
    public void exitPictureInPictureMode(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            api.exitPictureInPictureMode(playerMsg);
        }
    }

    @Override
    public void initImageSprite(@NonNull StringListPlayerMsg spriteInfo) {
        TXFlutterVodPlayerApi api = getPlayer(spriteInfo.getPlayerId());
        if (null != api) {
            api.initImageSprite(spriteInfo);
        }
    }

    @NonNull
    @Override
    public UInt8ListMsg getImageSprite(@NonNull DoublePlayerMsg time) {
        TXFlutterVodPlayerApi api = getPlayer(time.getPlayerId());
        if (null != api) {
            return api.getImageSprite(time);
        }
        return null;
    }

    @NonNull
    @Override
    public DoubleMsg getDuration(@NonNull PlayerMsg playerMsg) {
        TXFlutterVodPlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.getDuration(playerMsg);
        }
        return null;
    }
}
