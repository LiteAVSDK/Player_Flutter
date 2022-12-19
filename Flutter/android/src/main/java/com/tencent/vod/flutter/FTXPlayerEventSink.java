// Copyright (c) 2022 Tencent. All rights reserved.

package com.tencent.vod.flutter;

import java.util.LinkedList;
import java.util.Queue;

import io.flutter.plugin.common.EventChannel;

/**
 * handle flutter event
 */
public class FTXPlayerEventSink implements EventChannel.EventSink {

    private EventChannel.EventSink eventSink;
    private Queue<Object> eventQueue = new LinkedList();
    private boolean isEnd = false;

    public void setEventSinkProxy(EventChannel.EventSink es) {
        this.eventSink = es;
        consume();
    }

    private void enqueue(Object event) {
        if (isEnd) {
            return;
        }
        eventQueue.offer(event);
    }

    private void consume() {
        if (eventSink == null) {
            return;
        }
        while (!eventQueue.isEmpty()) {
            Object event = eventQueue.poll();
            if (event instanceof EndEvent) {
                eventSink.endOfStream();
            } else if (event instanceof ErrorEvent) {
                ErrorEvent errorEvent = (ErrorEvent) event;
                eventSink.error(errorEvent.code, errorEvent.message, errorEvent.details);
            } else {
                eventSink.success(event);
            }
        }
    }

    private static class EndEvent {

    }

    private static class ErrorEvent {
        String code;
        String message;
        Object details;

        ErrorEvent(String code, String message, Object details) {
            this.code = code;
            this.message = message;
            this.details = details;
        }
    }

    @Override
    public void success(Object event) {
        enqueue(event);
        consume();
    }

    @Override
    public void error(String errorCode, String errorMessage, Object errorDetails) {
        enqueue(new ErrorEvent(errorCode, errorMessage, errorDetails));
        consume();
    }

    @Override
    public void endOfStream() {
        enqueue(new EndEvent());
        consume();
        isEnd = true;
    }
}
