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
            final ExecutionContext context
    ) {
        context.getLogger().info("Java Service Bus Queue trigger function executed.");
        context.getLogger().info(message);
    }
}
