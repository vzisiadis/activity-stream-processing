# Activity Stream Processing

[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnianton%2Factivity-stream-processing%2Fmain%2Fdeploy%2Fazure.deploy.json)


This is a templated deployment of a sample Azure architecture for implementing an User activity/event stream processing, having all the related PaaS components.

The architecture of the solution is as depicted on the following diagram:

![Artitectural Diagram](./assets/azure-deployment-diagram.png?raw=true)

## The role of each component
* **Ingestion Function App** -public facing HTTP endpoint (or Kafka consumer)
* **Event Hubs** -event streaming service
* **Steam Analytics** -to aggregate specific event that needed to be further consolidated before being processed
* **Processor & Notification Function Apps** -Function Applications to process the incoming events and notify downstream systems respectively
* **Application Insights** to provide monitoring and visibility for the health and performance of the application
* **Service Bus** -reliable message broker to decouple processing and notification flows, external APIs may need throttling etc
* **Azure Key Vault** responsible to securely store the secrets/credentials for the PaaS services 

In an enterprise grade environment, all PaaS services can leverage **Private Endpoints** to be accessible only within a private Virtual Network and **App Gateway (WAF)** or **Azure Front Door** can be used to accept the incoming requests (not included in the present deployment).

<br>

---
Based on the template repository (**[https://github.com/nianton/bicep-starter](https://github.com/nianton/azure-naming#bicep-azure-naming)**) to get started with an bicep infrastructure-as-code project, including the azure naming module to facilitate naming conventions. 

For the full reference of the supported naming for Azure resource types, head to the main module repository: **[https://github.com/nianton/azure-naming](https://github.com/nianton/azure-naming#bicep-azure-naming-module)**
