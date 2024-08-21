package com.tencent.vod.flutter.live.egl;

public interface EGLHelper<T> {

    /**
     * 返回EGLContext，用于创建共享EGLContext等。
     */
    T getContext();

    /**
     * 将EGLContext绑定到当前线程，以及Helper中保存的draw Surface和read Surface。
     */
    void makeCurrent();

    /**
     * 解除当前线程绑定的EGLContext、draw Surface、read Surface。
     */
    void unmakeCurrent();

    /**
     * 将渲染的内容刷到绑定的绘制目标上。
     */
    boolean swapBuffers();

    /**
     * 销毁创建的EGLContext以及相关的资源。
     */
    void destroy();
}
