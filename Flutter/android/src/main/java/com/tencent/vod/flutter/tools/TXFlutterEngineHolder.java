package com.tencent.vod.flutter.tools;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.liteav.base.util.LiteavLog;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class TXFlutterEngineHolder {

    private static final String TAG = "TXFlutterEngineHolder";

    private static final class SingletonInstance {
        private static final TXFlutterEngineHolder instance = new TXFlutterEngineHolder();
    }

    private int mFrontContextCount = 0;
    private Application.ActivityLifecycleCallbacks mLifeCallback;
    private final List<TXAppStatusListener> mListeners = new ArrayList<>();
    private boolean mIsEnterBack = false;

    private final List<WeakReference<Activity>> mActivityList = new ArrayList<>();

    public static TXFlutterEngineHolder getInstance() {
        return SingletonInstance.instance;
    }

    public void attachBindLife(FlutterPlugin.FlutterPluginBinding binding) {
        if (mLifeCallback != null) {
            LiteavLog.w(TAG, "TXFlutterEngineHolder is already attached");
            return;
        }
        if (null == binding) {
            return;
        }
        mLifeCallback = new Application.ActivityLifecycleCallbacks() {

            @Override
            public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {

            }

            @Override
            public void onActivityStarted(@NonNull Activity activity) {
                mFrontContextCount++;
                LiteavLog.i(TAG, "activity is started:" + activity);
                if (mIsEnterBack && mFrontContextCount > 0) {
                    mIsEnterBack = false;
                    notifyResume();
                }
            }

            @Override
            public void onActivityResumed(@NonNull Activity activity) {
                synchronized (mActivityList) {
                    LiteavLog.i(TAG, "activity is resumed:" + activity);
                    int index = findIndexByAct(activity);
                    if (index >= 0) {
                        // refresh index
                        mActivityList.remove(index);
                    }
                    mActivityList.add(new WeakReference<>(activity));
                }
            }

            @Override
            public void onActivityPaused(@NonNull Activity activity) {

            }

            @Override
            public void onActivityStopped(@NonNull Activity activity) {
                mFrontContextCount--;
                LiteavLog.i(TAG, "activity is stopped:" + activity);
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
                synchronized (mActivityList) {
                    LiteavLog.i(TAG, "activity is destroyed:" + activity);
                    int index = findIndexByAct(activity);
                    if (index >= 0) {
                        mActivityList.remove(index);
                    }
                }
            }
        };
        ((Application)binding.getApplicationContext()).registerActivityLifecycleCallbacks(mLifeCallback);
    }

    private int findIndexByAct(Activity activity) {
        synchronized (mActivityList) {
            int index = -1;
            for (int i = 0; i < mActivityList.size(); i++) {
                WeakReference<Activity> weakReference = mActivityList.get(i);
                if (weakReference.get() == activity) {
                    index = i;
                    break;
                }
            }
            return index;
        }
    }

    public boolean isInForeground() {
        return !mIsEnterBack;
    }

    public Activity getActivityByIndex(int index) {
        synchronized (mActivityList) {
            if (index >= mActivityList.size() || index < 0) {
                return null;
            }
            return mActivityList.get(index).get();
        }
    }

    public Activity getPreActivity() {
        synchronized (mActivityList) {
            final int size = mActivityList.size();
            final int preIndex = size - 2;
            return getActivityByIndex(preIndex);
        }
    }

    public Activity getCurActivity() {
        synchronized (mActivityList) {
            final int size = mActivityList.size();
            final int preIndex = size - 1;
            return getActivityByIndex(preIndex);
        }
    }

    public void destroy(FlutterPlugin.FlutterPluginBinding binding) {
        LiteavLog.i(TAG, "called engine holder destroy");
        if (null == mLifeCallback) {
            return;
        }
        if (null == binding) {
            return;
        }
        ((Application)binding.getApplicationContext()).unregisterActivityLifecycleCallbacks(mLifeCallback);
        mLifeCallback = null;
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
