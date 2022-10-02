Compress-Archive -Path in


Compress-Archive -Path .\ingestorFunctionApp\target\azure-functions\func-app-name\* -DestinationPath ./ingestorDeploy.zip
Compress-Archive -Path .\processorFunctionApp\target\azure-functions\func-app-name\* -DestinationPath ./processorDeploy.zip
Compress-Archive -Path .\notifierFunctionApp\target\azure-functions\func-app-name\* -DestinationPath ./notifierDeploy.zip


az functionapp deployment source config-zip -g rg-acts-dev -n func-ingestor-acts-dev --src .\ingestorDeploy.zip

Compress-Archive -Path .\processorFunctionApp\target\azure-functions\func-app-name\* -DestinationPath ./processorDeploy.zip
az functionapp deployment source config-zip -g rg-acts-dev -n func-processor-acts-dev --src .\processorDeploy.zip

Compress-Archive -Path .\notifierFunctionApp\target\azure-functions\func-app-name\* -DestinationPath ./notifierDeploy.zip
az functionapp deployment source config-zip -g rg-acts-dev -n func-notifier-acts-dev --src .\notifierDeploy.zip