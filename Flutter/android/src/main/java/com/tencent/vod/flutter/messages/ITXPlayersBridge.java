// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter.messages;

import android.util.SparseArray;
import com.tencent.vod.flutter.FTXBasePlayer;

public interface ITXPlayersBridge {

    /**
     * Get player list.
     *
     * 获得播放器列表
     */
    SparseArray<FTXBasePlayer> getPlayers();
}
