// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.tools;

import android.content.res.Resources;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;
import com.tencent.vod.flutter.FTXEvent;
import com.tencent.vod.flutter.messages.FtxMessages.BoolMsg;
import com.tencent.vod.flutter.messages.FtxMessages.DoubleMsg;
import com.tencent.vod.flutter.messages.FtxMessages.IntMsg;
import com.tencent.vod.flutter.messages.FtxMessages.ListMsg;
import com.tencent.vod.flutter.messages.FtxMessages.PlayerMsg;
import com.tencent.vod.flutter.messages.FtxMessages.StringMsg;
import com.tencent.vod.flutter.messages.FtxMessages.UInt8ListMsg;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Common utility class.
 * <p>
 * 通用工具类
 */
public class TXCommonUtil {

    private static final String TAG = "TXCommonUtil";

    private static final String KEY_MAX_BRIGHTNESS = "max_brightness";
    private static final String KEY_IS_MIUI = "is_miui";

    private static final Map<String, Object> CACHE_MAP = new HashMap<>();

    static final Map<Integer, Integer> DOWNLOAD_STATE_MAP = new HashMap<Integer, Integer>() {{
        put(TXVodDownloadMediaInfo.STATE_INIT, FTXEvent.EVENT_DOWNLOAD_START);
        put(TXVodDownloadMediaInfo.STATE_START, FTXEvent.EVENT_DOWNLOAD_PROGRESS);
        put(TXVodDownloadMediaInfo.STATE_FINISH, FTXEvent.EVENT_DOWNLOAD_FINISH);
        put(TXVodDownloadMediaInfo.STATE_STOP, FTXEvent.EVENT_DOWNLOAD_STOP);
        put(TXVodDownloadMediaInfo.STATE_ERROR, FTXEvent.EVENT_DOWNLOAD_ERROR);
    }};

    /**
     * 获取最大亮度,兼容MIUI部分系统亮度最大值不是255的情况.
     * MIUI在android 13以后，系统最大亮度与配置不符，变为128
     * <p>
     * Get the maximum brightness, compatible with some MIUI systems where the maximum brightness is not 255.
     * After Android 13, MIUI's maximum brightness is inconsistent with the configuration and becomes 128.
     *
     * @return max
     */
    public static float getBrightnessMax() {
        if (CACHE_MAP.containsKey(KEY_MAX_BRIGHTNESS)) {
            //noinspection ConstantConditions
            return (float) CACHE_MAP.get(KEY_MAX_BRIGHTNESS);
        }
        float maxBrightness = 255f;
        try {
            Resources system = Resources.getSystem();
            int resId = system.getIdentifier("config_screenBrightnessSettingMaximum",
                    "integer", "android");
            if (resId != 0) {
                maxBrightness = system.getInteger(resId);
            }
        } catch (Exception e) {
            Log.getStackTraceString(e);
        }
        if (TXCommonUtil.isMIUI() && Build.VERSION.SDK_INT >= 33) {
            maxBrightness = 128F;
        }
        CACHE_MAP.put(KEY_MAX_BRIGHTNESS, maxBrightness);
        return maxBrightness;
    }

    public static boolean isMIUI() {
        if (CACHE_MAP.containsKey(KEY_IS_MIUI)) {
            //noinspection ConstantConditions
            return (boolean) CACHE_MAP.get(KEY_IS_MIUI);
        } else {
            String pro = Build.MANUFACTURER;
            boolean isMiui = TextUtils.equals(pro, "Xiaomi");
            CACHE_MAP.put(KEY_IS_MIUI, isMiui);
            return isMiui;
        }
    }

    public static Map<String, Object> getParams(int event, Bundle bundle) {
        Map<String, Object> param = new HashMap<>();
        if (event != 0) {
            param.put("event", event);
        }

        if (bundle != null && !bundle.isEmpty()) {
            Set<String> keySet = bundle.keySet();
            for (String key : keySet) {
                Object val = bundle.get(key);
                param.put(key, val);
            }
        }

        return param;
    }

    public static Map<String, Object> transToMap(Bundle bundle) {
        Map<String, Object> param = new HashMap<>();
        if (bundle != null && !bundle.isEmpty()) {
            Set<String> keySet = bundle.keySet();
            for (String key : keySet) {
                Object val = bundle.get(key);
                param.put(key, val);
            }
        }

        return param;
    }

    public static int getDownloadEventByState(int mediaInfoDownloadState) {
        Integer event = DOWNLOAD_STATE_MAP.get(mediaInfoDownloadState);
        return null != event ? event : FTXEvent.EVENT_DOWNLOAD_ERROR;
    }

    public static PlayerMsg playerMsgWith(Long textureId) {
        PlayerMsg msg = new PlayerMsg();
        msg.setPlayerId(textureId);
        return msg;
    }

    public static StringMsg stringMsgWith(String str) {
        StringMsg msg = new StringMsg();
        msg.setValue(str);
        return msg;
    }

    public static DoubleMsg doubleMsgWith(Double value) {
        DoubleMsg msg = new DoubleMsg();
        msg.setValue(value);
        return msg;
    }

    public static BoolMsg boolMsgWith(Boolean value) {
        BoolMsg msg = new BoolMsg();
        msg.setValue(value);
        return msg;
    }

    public static IntMsg intMsgWith(Long value) {
        IntMsg msg = new IntMsg();
        msg.setValue(value);
        return msg;
    }

    public static UInt8ListMsg uInt8ListMsg(byte[] data) {
        UInt8ListMsg msg = new UInt8ListMsg();
        msg.setValue(data);
        return msg;
    }

    public static ListMsg listMsgWith(List<Object> value) {
        ListMsg msg = new ListMsg();
        msg.setValue(value);
        return msg;
    }
}
