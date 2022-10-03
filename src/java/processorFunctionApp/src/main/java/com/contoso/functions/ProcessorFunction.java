package com.contoso.functions;

import com.azure.messaging.eventhubs.EventData;
import com.microsoft.azure.functions.annotation.*;
import com.microsoft.azure.functions.*;

import java.time.ZonedDateTime;
import java.util.*;
import java.util.logging.Logger;

/**
 * Azure Functions with Event Hub trigger.
 */
public class ProcessorFunction {
    /**
     * This function will be invoked when an event is received from Event Hub.
     */
    @FunctionName("ProcessorFunction")
    public void run(
        @EventHubTrigger(name = "messages", eventHubName = "%EventHubName%", connection = "EventHubsConnection", consumerGroup = "%EventHubConsumerGroup%", cardinality = Cardinality.ONE) String message,
        @BindingName("Properties") Map<String, Object> properties,
        @BindingName("SystemProperties") Map<String, Object> systemProperties,
        @BindingName("PartitionContext") Map<String, Object> partitionContext,
        @BindingName("EnqueuedTimeUtc") Object enqueuedTimeUtc,
        final ExecutionContext context
    ) {
        Logger logger = context.getLogger();

        logger.info("ProcessorFunctionApp:ProcessorFunction - Java Event Hub trigger function executed.");
        logger.info(String.format("Enqueued: %s, message: %s", enqueuedTimeUtc.toString(), message));
        
        var et = ZonedDateTime.parse(enqueuedTimeUtc + "Z"); // needed as the UTC time presented does not have a TZ
        logger.info("Event hub message received: " + message + ", properties: " + properties);
        logger.info("Properties: " + properties);
        logger.info("System Properties: " + systemProperties);
        logger.info("partitionContext: " + partitionContext);
        logger.info("EnqueuedTimeUtc: " + et);

        //        messages.forEach(message -> context.getLogger().info(message.getPartitionKey()));
    }
}
