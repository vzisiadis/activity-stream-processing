package com.contoso.functions;

import com.microsoft.azure.functions.annotation.*;
import com.microsoft.azure.functions.*;

/**
 * Azure Functions with Service Bus Trigger.
 */
public class NofiticationDequeueFunction {
    /**
     * This function will be invoked when a new message is received at the Service Bus Queue.
     */
    @FunctionName("NofiticationDequeue")
    public void run(
            @ServiceBusQueueTrigger(name = "message", queueName = "%ServiceBueQueueName%", connection = "ServiceBusConnection") String message,
            @SendGridOutput(apiKey = "SendGridApiKey", from = "%SendGridFromEmail", subject = "fasdfasdf")OutputBinding<String> notification,
            final ExecutionContext context
    ) {
        
        context.getLogger().info("Java Service Bus Queue trigger function executed.");
        context.getLogger().info(message);
        notification.setValue("");
    }
}
