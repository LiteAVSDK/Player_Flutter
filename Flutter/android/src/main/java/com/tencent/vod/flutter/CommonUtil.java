// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import android.os.Bundle;
import com.tencent.rtmp.downloader.TXVodDownloadMediaInfo;
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
 * 通用工具类
 */
public class CommonUtil {

    static final Map<Integer, Integer> DOWNLOAD_STATE_MAP = new HashMap<Integer, Integer>() {{
        put(TXVodDownloadMediaInfo.STATE_INIT, FTXEvent.EVENT_DOWNLOAD_START);
        put(TXVodDownloadMediaInfo.STATE_START, FTXEvent.EVENT_DOWNLOAD_PROGRESS);
        put(TXVodDownloadMediaInfo.STATE_FINISH, FTXEvent.EVENT_DOWNLOAD_FINISH);
        put(TXVodDownloadMediaInfo.STATE_STOP, FTXEvent.EVENT_DOWNLOAD_STOP);
        put(TXVodDownloadMediaInfo.STATE_ERROR, FTXEvent.EVENT_DOWNLOAD_ERROR);
    }};

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
