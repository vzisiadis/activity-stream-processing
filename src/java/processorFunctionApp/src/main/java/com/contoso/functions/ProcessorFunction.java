package com.contoso.functions;

import com.azure.messaging.eventhubs.EventData;
import com.microsoft.azure.functions.annotation.*;
import com.microsoft.azure.functions.*;
import java.util.*;

/**
 * Azure Functions with Event Hub trigger.
 */
public class ProcessorFunction {
    /**
     * This function will be invoked when an event is received from Event Hub.
     */
    @FunctionName("ProcessorFunction")
    public void run(
        @EventHubTrigger(name = "messages", eventHubName = "%EventHubName%", connection = "EventHubConnection", consumerGroup = "%EventHubConsumerGroup%", cardinality = Cardinality.MANY) List<EventData> messages,
        int partitionId,
        Date enqueueTimeUtc,
        long sequenceNumber,
        String offset,
        final ExecutionContext context
    ) {
        context.getLogger().info("Java Event Hub trigger function executed.");
        context.getLogger().info("Length:" + messages.size());
        messages.forEach(message -> context.getLogger().info(message.getBodyAsString()));
    }
}
