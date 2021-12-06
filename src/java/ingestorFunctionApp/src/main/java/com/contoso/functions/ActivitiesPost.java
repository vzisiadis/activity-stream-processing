package com.contoso.functions;

import java.util.*;

import com.contoso.analytics.UserActivity;
import com.google.gson.Gson;
import com.microsoft.azure.functions.annotation.*;
import com.microsoft.azure.functions.*;

import javax.swing.text.html.Option;

/**
 * Azure Functions with HTTP Trigger.
 */
public class ActivitiesPost {
    /**
     * This function listens at endpoint "/api/ActivitiesPost". Two ways to invoke it using "curl" command in bash:
     * 1. curl -d "HTTP Body" {your host}/api/activities
     * 2. curl {your host}/api/ActivitiesPost?name=HTTP%20Query
     */
    @FunctionName("ActivitiesPost")
    public HttpResponseMessage run(
            @HttpTrigger(name = "req", methods = {HttpMethod.POST}, route = "activities", authLevel = AuthorizationLevel.FUNCTION) HttpRequestMessage<Optional<String>> request,
            @EventHubOutput(name = "event", eventHubName = "%EventHubName%", connection = "EventHubConnection") OutputBinding<UserActivity> eventHubOutput,
            final ExecutionContext context) {
        context.getLogger().info("Java HTTP trigger processed a request.");

        Optional<String> body = request.getBody();

        if (body.isEmpty()) {
            return request.createResponseBuilder(HttpStatus.BAD_REQUEST).body("Please pass a name on the query string or in the request body").build();
        }

        String userActivityJson = body.get();
        Gson gson = new Gson();
        UserActivity userActivity = gson.fromJson(userActivityJson, UserActivity.class);
        eventHubOutput.setValue(userActivity);

        return request.createResponseBuilder(HttpStatus.OK)
                .header("Content-Type", "application/json")
                .body(userActivityJson)
                .build();
    }
}
