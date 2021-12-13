package com.contoso.functions;

import com.microsoft.azure.functions.annotation.*;
import com.microsoft.azure.functions.*;
import com.google.gson.*;

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
            @SendGridOutput(apiKey = "SendGridApiKey", from = "%SendGridFromEmail", subject = "fasdfasdf", text = "", to = "", name = "")OutputBinding<String> notification,
            final ExecutionContext context
    ) {
        context.getLogger().info("NofiticationDequeue: Java Service Bus Queue trigger function executed.");
        context.getLogger().info(message);
        
        // Example process: Notify by email through SendGrid    
        JsonObject sendGridRequest = buildSendGridPayload("Sample email from Function");
        notification.setValue(sendGridRequest.toString());
    }

    /**
     * This function builds the request expected by SendGrid API.
     * Sendgrid documentation: https://docs.sendgrid.com/api-reference/mail-send/mail-send
     */
    private JsonObject buildSendGridPayload(String subject) {

        
        JsonObject request = new JsonObject();
        JsonArray personalizations = new JsonArray();

        request.add("personalizations", personalizations);
        request.addProperty("subject", subject);
        request.add("from", buildEmailAddress("name", System.getenv("SendGridFromEmail")));        
        
        // TODO: Replace with user email address
        request.add("to", buildEmailAddress("name", System.getenv("SendGridFromEmail"))); 
        request.add("contents", toArray(buildContent("text/html", "<p>Hello from Notification App!</p><p>Dear user, we are sending an email reacting in the best way to <strong>your input</strong>.</p>")));

        return request;
    }

    private JsonObject buildEmailAddress(String name, String address) {
        JsonObject emailAddress  = new JsonObject();
        emailAddress.addProperty("name", name);
        emailAddress.addProperty("address", address);

        return emailAddress;
    }

    private JsonObject buildContent(String type, String value) {
        JsonObject content  = new JsonObject();
        content.addProperty("type", type);
        content.addProperty("value", value);

        return content;
    }

    private JsonArray toArray(JsonObject jsonObject) {
        JsonArray jsonArray = new JsonArray();
        jsonArray.add(jsonObject);
        return jsonArray;
    }
}
