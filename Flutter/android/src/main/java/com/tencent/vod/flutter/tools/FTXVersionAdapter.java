package com.tencent.vod.flutter.tools;

import com.tencent.liteav.base.util.LiteavLog;
import com.tencent.rtmp.TXVodConstants;
import com.tencent.rtmp.TXVodPlayConfig;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;

public class FTXVersionAdapter {

    private static final String TAG = "FTXVersionAdapter";

    public static void enableCustomSubtitle(TXVodPlayConfig config, int isOpen) {
        if (null == config) {
            config = new TXVodPlayConfig();
        }
        Map<String, Object> extInfo = safeGetExtInfo(config);
        String customKeyName = getVodKeyValue("PLAYER_OPTION_KEY_SUBTITLE_OUTPUT_TYPE");
        if (null != customKeyName) {
            extInfo.put(customKeyName, isOpen);
            config.setExtInfo(extInfo);
        }
    }

    public static void enableDrmLevel3(TXVodPlayConfig config, boolean isOpen) {
        if (null == config) {
            config = new TXVodPlayConfig();
        }
        Map<String, Object> extInfo = safeGetExtInfo(config);
        String customKeyName = getVodKeyValue("VOD_USE_DRM_L3");
        if (null != customKeyName) {
            extInfo.put(customKeyName, isOpen);
            config.setExtInfo(extInfo);
        }
    }

    private static Map<String, Object> safeGetExtInfo(TXVodPlayConfig config) {
        Map<String, Object> extInfo = config.getExtInfoMap();
        if (extInfo == null) {
            extInfo = new HashMap<>();
        }
        //noinspection UnnecessaryLocalVariable
        Map<String, Object> canModifyMap = new HashMap<>(extInfo);
        return canModifyMap;
    }

    public static String getVodKeyValue(String paramDeclareName) {
        try {
            Class<?> clazz = TXVodConstants.class;
            Field field = clazz.getDeclaredField(paramDeclareName);
            field.setAccessible(true);
            Object value = field.get(null);
            return (String) value;
        } catch (NoSuchFieldException | IllegalAccessException e) {
            LiteavLog.e(TAG, "vod key obtain failed, maybe version is too low", e);
        }
        return null;
    }

}
