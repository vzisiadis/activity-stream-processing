package com.contoso.functions;

import java.util.*;
import com.microsoft.azure.functions.annotation.*;
import com.microsoft.azure.functions.*;

/**
 * Azure Functions with HTTP Trigger.
 */
public class HealthCheckFunction {
    /**
     * This function listens at endpoint "/api/healthcheck". Two ways to invoke it using "curl" command in bash:
     * 1. curl -d "HTTP Body" {your host}/api/healthcheck
     * 2. curl {your host}/api/healthcheck
     */
    @FunctionName("HealthCheck")
    public HttpResponseMessage run(
            @HttpTrigger(name = "req", methods = {HttpMethod.GET, HttpMethod.POST}, route = "healthcheck", authLevel = AuthorizationLevel.FUNCTION) HttpRequestMessage<Optional<String>> request,
            final ExecutionContext context) {
        context.getLogger().info("ProcessorFunctionApp:HealthCheck - Java HTTP trigger processed a request.");

        // TODO: Include more checks, e.g. for connection strings
        // All good, return 200/OK
        return request.createResponseBuilder(HttpStatus.OK).body("healthy - buildId: ").build();
    }
}