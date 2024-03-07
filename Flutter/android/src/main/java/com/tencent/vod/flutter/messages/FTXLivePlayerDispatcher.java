// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.messages;

import androidx.annotation.NonNull;

import com.tencent.vod.flutter.FTXBasePlayer;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.BoolPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.FTXLivePlayConfigPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PipParamsPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringIntPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringPlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.TXFlutterLivePlayerApi;

@SuppressWarnings("ConstantConditions")
public class FTXLivePlayerDispatcher implements FtxMessages.TXFlutterLivePlayerApi {

    final ITXPlayersBridge bridge;

    public FTXLivePlayerDispatcher(@NonNull ITXPlayersBridge dataBridge) {
        this.bridge = dataBridge;
    }

    TXFlutterLivePlayerApi getPlayer(Long playerID) {
        if (null != playerID) {
            FTXBasePlayer ftxBasePlayer = bridge.getPlayers().get(playerID.intValue());
            if (ftxBasePlayer instanceof FtxMessages.TXFlutterLivePlayerApi) {
                return (TXFlutterLivePlayerApi) ftxBasePlayer;
            }
        }
        return null;
    }

    @NonNull
    @Override
    public IntMsg initialize(@NonNull BoolPlayerMsg onlyAudio) {
        TXFlutterLivePlayerApi api = getPlayer(onlyAudio.getPlayerId());
        if (null != api) {
            return api.initialize(onlyAudio);
        }
        return null;
    }

    @NonNull
    @Override
    public BoolMsg startLivePlay(@NonNull StringIntPlayerMsg playerMsg) {
        TXFlutterLivePlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.startLivePlay(playerMsg);
        }
        return null;
    }

    @NonNull
    @Override
    public BoolMsg stop(@NonNull BoolPlayerMsg isNeedClear) {
        TXFlutterLivePlayerApi api = getPlayer(isNeedClear.getPlayerId());
        if (null != api) {
            return api.stop(isNeedClear);
        }
        return null;
    }

    @NonNull
    @Override
    public BoolMsg isPlaying(@NonNull PlayerMsg playerMsg) {
        TXFlutterLivePlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            return api.isPlaying(playerMsg);
        }
        return null;
    }

    @Override
    public void pause(@NonNull PlayerMsg playerMsg) {
        TXFlutterLivePlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            api.pause(playerMsg);
        }
    }

    @Override
    public void resume(@NonNull PlayerMsg playerMsg) {
        TXFlutterLivePlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            api.resume(playerMsg);
        }
    }

    @Override
    public void setLiveMode(@NonNull IntPlayerMsg mode) {
        TXFlutterLivePlayerApi api = getPlayer(mode.getPlayerId());
        if (null != api) {
            api.setLiveMode(mode);
        }
    }

    @Override
    public void setVolume(@NonNull IntPlayerMsg volume) {
        TXFlutterLivePlayerApi api = getPlayer(volume.getPlayerId());
        if (null != api) {
            api.setVolume(volume);
        }
    }

    @Override
    public void setMute(@NonNull BoolPlayerMsg mute) {
        TXFlutterLivePlayerApi api = getPlayer(mute.getPlayerId());
        if (null != api) {
            api.setMute(mute);
        }
    }

    @NonNull
    @Override
    public IntMsg switchStream(@NonNull StringPlayerMsg url) {
        TXFlutterLivePlayerApi api = getPlayer(url.getPlayerId());
        if (null != api) {
            return api.switchStream(url);
        }
        return null;
    }

    @Override
    public void setAppID(@NonNull StringPlayerMsg appId) {
        TXFlutterLivePlayerApi api = getPlayer(appId.getPlayerId());
        if (null != api) {
            api.setAppID(appId);
        }
    }

    @Override
    public void setConfig(@NonNull FTXLivePlayConfigPlayerMsg config) {
        TXFlutterLivePlayerApi api = getPlayer(config.getPlayerId());
        if (null != api) {
            api.setConfig(config);
        }
    }

    @NonNull
    @Override
    public BoolMsg enableHardwareDecode(@NonNull BoolPlayerMsg enable) {
        TXFlutterLivePlayerApi api = getPlayer(enable.getPlayerId());
        if (null != api) {
            return api.enableHardwareDecode(enable);
        }
        return null;
    }

    @NonNull
    @Override
    public IntMsg enterPictureInPictureMode(@NonNull PipParamsPlayerMsg pipParamsMsg) {
        TXFlutterLivePlayerApi api = getPlayer(pipParamsMsg.getPlayerId());
        if (null != api) {
            return api.enterPictureInPictureMode(pipParamsMsg);
        }
        return null;
    }

    @Override
    public void exitPictureInPictureMode(@NonNull PlayerMsg playerMsg) {
        TXFlutterLivePlayerApi api = getPlayer(playerMsg.getPlayerId());
        if (null != api) {
            api.exitPictureInPictureMode(playerMsg);
        }
    }
}
