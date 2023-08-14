package com.tencent.vod.flutter.tools;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

public class TXFlutterEngineHolder {

    private static final String TAG = "TXFlutterEngineHolder";

    private int mFrontContextCount = 0;
    private Application.ActivityLifecycleCallbacks mLifeCallback;

    public void attachBindLife(ActivityPluginBinding binding) {
        if (mLifeCallback != null) {
            Log.w(TAG, "TXFlutterEngineHolder is already attach");
            return;
        }
        if (null == binding) {
            return;
        }
        if (binding.getActivity().isDestroyed() || binding.getActivity().isFinishing()) {
            return;
        }
        if (null == binding.getActivity().getApplication()) {
            return;
        }
        mLifeCallback = new Application.ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {

            }

            @Override
            public void onActivityStarted(@NonNull Activity activity) {
                mFrontContextCount++;
            }

            @Override
            public void onActivityResumed(@NonNull Activity activity) {

            }

            @Override
            public void onActivityPaused(@NonNull Activity activity) {

            }

            @Override
            public void onActivityStopped(@NonNull Activity activity) {
                mFrontContextCount--;
            }

            @Override
            public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {

            }

            @Override
            public void onActivityDestroyed(@NonNull Activity activity) {

            }
        };
        binding.getActivity().getApplication().registerActivityLifecycleCallbacks(mLifeCallback);
    }

    public boolean isInForeground() {
        return mFrontContextCount > 0;
    }

    public void destroy(ActivityPluginBinding binding) {
        if (null == mLifeCallback) {
            return;
        }
        if (null == binding) {
            return;
        }
        if (binding.getActivity().isDestroyed()) {
            return;
        }
        if (null == binding.getActivity().getApplication()) {
            return;
        }
        binding.getActivity().getApplication().unregisterActivityLifecycleCallbacks(mLifeCallback);
    }
}
