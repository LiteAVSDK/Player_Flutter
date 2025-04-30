package com.tencent.vod.flutter.tools;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * use to communicate with Activities frequently
 */
public class TXSimpleEventBus {

    private static TXSimpleEventBus instance;
    private final Map<String, List<EventSubscriber>> subscribers = new HashMap<>();

    private TXSimpleEventBus() {
    }

    public static TXSimpleEventBus getInstance() {
        if (instance == null) {
            instance = new TXSimpleEventBus();
        }
        return instance;
    }

    public void register(String eventType, EventSubscriber subscriber) {
        List<EventSubscriber> subscriberList = subscribers.get(eventType);
        if (subscriberList == null) {
            subscriberList = new ArrayList<>();
            subscribers.put(eventType, subscriberList);
        }
        subscriberList.add(subscriber);
    }

    public void unregister(String eventType, EventSubscriber subscriber) {
        List<EventSubscriber> subscriberList = subscribers.get(eventType);
        if (subscriberList != null) {
            subscriberList.remove(subscriber);
        }
    }

    public void unregisterAllType(EventSubscriber subscriber) {
        Set<String> keySets = subscribers.keySet();
        for (String key : keySets) {
            List<EventSubscriber> subscriberList = subscribers.get(key);
            if (subscriberList != null) {
                subscriberList.remove(subscriber);
            }
        }
    }

    public void post(String eventType, Object data) {
        List<EventSubscriber> subscriberList = subscribers.get(eventType);
        if (subscriberList != null) {
            for (EventSubscriber subscriber : subscriberList) {
                subscriber.onEvent(eventType, data);
            }
        }
    }

    public interface EventSubscriber {
        void onEvent(String eventType, Object data);
    }
}
