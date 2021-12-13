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
        @EventHubTrigger(name = "messages", eventHubName = "%EventHubName%", connection = "EventHubConnection", consumerGroup = "%EventHubConsumerGroup%", cardinality = Cardinality.ONE) String message,
        String partitionKey,
        Date enqueuedTimeUtc,
        long sequenceNumber,
        long offset,
        final ExecutionContext context
    ) {
        context.getLogger().info("ProcessorFunctionApp:ProcessorFunction - Java Event Hub trigger function executed.");
        context.getLogger().info(String.format("Enqueued: %s, message: %s", enqueuedTimeUtc.toString(), message));

//        context.getLogger().info("Length:" + messages.size());
//        messages.forEach(message -> context.getLogger().info(message.getPartitionKey()));
    }
}
