package com.tencent.vod.flutter.live.render;

public class FTXSize {
    public int width;
    public int height;

    public FTXSize() {
    }

    public FTXSize(int width, int height) {
        this.width = width;
        this.height = height;
    }

    @SuppressWarnings("SuspiciousNameCombination")
    public void swap() {
        int temp = width;
        width = height;
        height = temp;
    }
}
