package com.example.super_player;

import android.app.Activity;
import android.content.Context;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class SuperPlatformViewFactory extends PlatformViewFactory {
    /**
     * @param createArgsCodec the codec used to decode the args parameter of {@link #create}.
     */

    private FlutterPlugin.FlutterPluginBinding mFlutterPluginBinding;
    private Activity mActivity;

    public SuperPlatformViewFactory(FlutterPlugin.FlutterPluginBinding flutterPluginBinding, Activity activity) {
        super(StandardMessageCodec.INSTANCE);
        mFlutterPluginBinding = flutterPluginBinding;
        mActivity = activity;
    }
    
    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        if (mActivity == null) {
            return null;
        }

        if (args instanceof Map) {
            SuperPlatformPlayerView playerView = new SuperPlatformPlayerView(mActivity, ((Map) args), viewId, mFlutterPluginBinding);
            return playerView;
        }

        return null;
    }
}
