package com.tencent.vod.flutter.ui.render;

import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.player.render.FTXPlayerRenderHost;

import java.util.Map;

import io.flutter.plugin.platform.PlatformView;

public class FTXRenderView implements PlatformView {
    private static final String TAG = "FTXRenderView";

    private FTXRenderCarrier mTextureView;
    private FTXPlayerRenderHost mBasePlayer;
    private final int mViewId;
    private final Context mContext;
    private final FrameLayout mContainer;
    private final int mRenderType;

    public FTXRenderView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams) {
        if (null != creationParams) {
            Object renderTypeObj = creationParams.get(FTXEvent.RENDER_TYPE_KEY);
            if (renderTypeObj instanceof Integer) {
                mRenderType = (int) renderTypeObj;
            } else {
                mRenderType = FTXEvent.ViewType.TEXTURE_TYPE;
            }
        } else {
            mRenderType = FTXEvent.ViewType.TEXTURE_TYPE;
        }
        mContext = context;
        mContainer = new FrameLayout(context);
        mContainer.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        resetRenderView();
        LiteavLog.i(TAG, "view " + id + " is created， renderType:" + mRenderType);
        mViewId = id;
    }

    public FTXRenderCarrier getRenderView() {
        return mTextureView;
    }

    private void resetRenderView() {
        if (mRenderType == FTXEvent.ViewType.TEXTURE_TYPE) {
            mTextureView = new FTXTextureView(mContext);
        } else if (mRenderType == FTXEvent.ViewType.SURFACE_TYPE
                || mRenderType == FTXEvent.ViewType.DRM_SURFACE_TYPE) {
            mTextureView = new FTXSurfaceView(mContext);
        } else {
            LiteavLog.e(TAG, "unknown view type :" + mRenderType + ", use default type TEXTURE_TYPE");
            mTextureView = new FTXTextureView(mContext);
        }
        mContainer.addView((View) mTextureView);
    }

    public void setPlayer(FTXPlayerRenderHost player) {
        LiteavLog.i(TAG, "start setPlayer, viewId:" + mViewId);
        if (mBasePlayer != player) {
            LiteavLog.i(TAG, "setPlayer, player is not equal, old:" + mBasePlayer
                    + ",new:" + player + ", view:" + hashCode());
            if (null != mBasePlayer) {
                mBasePlayer.setRenderView(null);
                clearTexture();
            }
            mBasePlayer = player;
        } else {
            LiteavLog.i(TAG, "setPlayer, player is same, player:" + player
                    + " refresh it, view:" + hashCode());
        }
        mTextureView.setVisibility(View.VISIBLE);
        player.setRenderView(mTextureView);
    }

    public void clearTexture() {
        final View oldView = (View) mTextureView;
        mContainer.removeView(oldView);
        resetRenderView();
    }

    @Nullable
    @Override
    public View getView() {
        return mContainer;
    }

    public int getViewId() {
        return mViewId;
    }

    @Override
    public void dispose() {
        LiteavLog.i(TAG, "render view is dispose, id:" + mViewId + ", view:" + hashCode());
    }
}
