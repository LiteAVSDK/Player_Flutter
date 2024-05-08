package com.tencent.vod.flutter.tools;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

public class TXFlutterEngineHolder {

    private static final String TAG = "TXFlutterEngineHolder";

    private int mFrontContextCount = 0;
    private Application.ActivityLifecycleCallbacks mLifeCallback;
    private final List<TXAppStatusListener> mListeners = new ArrayList<>();
    private boolean mIsEnterBack = false;


    public void attachBindLife(ActivityPluginBinding binding) {
        if (mLifeCallback != null) {
            LiteavLog.w(TAG, "TXFlutterEngineHolder is already attach");
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
                if (mIsEnterBack && mFrontContextCount > 0) {
                    mIsEnterBack = false;
                    notifyResume();
                }
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
                if (!mIsEnterBack && mFrontContextCount <= 0) {
                    mIsEnterBack = true;
                    notifyEnterBack();
                }
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
        return !mIsEnterBack;
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

    public void addAppLifeListener(TXAppStatusListener listener) {
        synchronized (mListeners) {
            if (!mListeners.contains(listener)) {
                mListeners.add(listener);
            }
        }
    }

    public void removeAppLifeListener(TXAppStatusListener listener) {
        synchronized (mListeners) {
            mListeners.remove(listener);
        }
    }

    public void clearListener() {
        synchronized (mListeners) {
            mListeners.clear();
        }
    }

    private void notifyResume() {
        synchronized (mListeners) {
            for (TXAppStatusListener listener : mListeners) {
                listener.onResume();
            }
        }
    }

    private void notifyEnterBack() {
        synchronized (mListeners) {
            for (TXAppStatusListener listener : mListeners) {
                listener.onEnterBack();
            }
        }
    }

    public abstract static class TXAppStatusListener {
        public abstract void onResume();

        public abstract void onEnterBack();
    }
}
