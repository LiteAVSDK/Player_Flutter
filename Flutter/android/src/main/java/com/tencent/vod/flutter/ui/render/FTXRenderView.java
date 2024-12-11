package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.txcvodplayer.renderer.TextureRenderView;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.tencent.vod.flutter.FTXBasePlayer;
import com.tencent.vod.flutter.FTXLivePlayer;
import com.tencent.vod.flutter.FTXVodPlayer;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;

public class FTXRenderView implements PlatformView {

    private final TXCloudVideoView mVideoView;
    private FTXBasePlayer mBasePlayer;

    public FTXRenderView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams
            , BinaryMessenger messenger) {
        mVideoView = new TXCloudVideoView(context);
    }

    public TXCloudVideoView getRenderView() {
        return mVideoView;
    }

    public void setPlayer(FTXBasePlayer player) {
        if (mBasePlayer != player) {
            if (null != mBasePlayer) {
                mBasePlayer.setRenderView(null);
            }
            if (mBasePlayer instanceof FTXVodPlayer && player instanceof FTXLivePlayer) {
                mVideoView.setVisibility(View.VISIBLE);
            }
            mVideoView.removeVideoView();
            mBasePlayer = player;
            player.setRenderView(mVideoView);
        } else {
            mVideoView.setVisibility(View.VISIBLE);
            player.setRenderView(mVideoView);
        }
    }

    @Nullable
    @Override
    public View getView() {
        return mVideoView;
    }

    @Override
    public void dispose() {

    }
}
