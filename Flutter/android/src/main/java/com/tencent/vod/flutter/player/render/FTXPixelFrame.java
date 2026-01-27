package com.tencent.vod.flutter.player.render;

public class FTXPixelFrame {

    private int textureId;

    private Object glContext;

    private int width;

    private int height;

    public int getTextureId() {
        return textureId;
    }

    public void setTextureId(int textureId) {
        this.textureId = textureId;
    }

    public Object getGLContext() {
        return glContext;
    }

    public void setGLContext(Object glContext) {
        this.glContext = glContext;
    }

    public int getWidth() {
        return width;
    }

    public void setWidth(int width) {
        this.width = width;
    }

    public int getHeight() {
        return height;
    }

    public void setHeight(int height) {
        this.height = height;
    }
}
