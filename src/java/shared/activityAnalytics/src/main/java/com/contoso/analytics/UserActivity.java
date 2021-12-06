package com.contoso.analytics;

import java.util.Date;

public class UserActivity {
    private String userId;
    private String sessionId;
    private Date timestamp;
    private String channel;
    private String page;
    private String event;
    private String eventPayload;
    private String source;

    public String userId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String sessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public Date timestamp() {
        return timestamp;
    }

    public void setTimestamp(Date timestamp) {
        this.timestamp = timestamp;
    }

    public String channel() {
        return channel;
    }

    public void setChannel(String channel) {
        this.channel = channel;
    }

    public String page() {
        return page;
    }

    public void setPage(String page) {
        this.page = page;
    }

    public String event() {
        return event;
    }

    public void setEvent(String event) {
        this.event = event;
    }

    public String eventPayload() {
        return eventPayload;
    }

    public void setEventPayload(String eventPayload) {
        this.eventPayload = eventPayload;
    }

    public String source() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    @Override
    public String toString() {
        return "UserActivity{" +
                "userId='" + userId + '\'' +
                ", sessionId='" + sessionId + '\'' +
                ", timestamp=" + timestamp +
                ", channel='" + channel + '\'' +
                ", page='" + page + '\'' +
                ", event='" + event + '\'' +
                ", eventPayload='" + eventPayload + '\'' +
                ", source='" + source + '\'' +
                '}';
    }
}