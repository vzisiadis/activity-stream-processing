@description('Location for the resources.')
param location string = resourceGroup().location
param tags object = {}

@minLength(3)
@maxLength(63)
@description('Stream Analytics Job Name, can contain alphanumeric characters and hypen and must be 3-63 characters long')
param name string

@minValue(1)
@maxValue(48)
@allowed([
  1
  3
  6
  12
  18
  24
  30
  36
  42
  48
])
@description('Number of Streaming Units')
param numberOfStreamingUnits int

resource streamAnalyticsJobName_resource 'Microsoft.StreamAnalytics/streamingjobs@2020-03-01' = {
  name: name
  location: location
  tags: union(tags, {
    displayName: name
  })
  properties: {
    sku: {
      name: 'Standard'
    }
    outputErrorPolicy: 'Stop'
    eventsOutOfOrderPolicy: 'Adjust'
    eventsOutOfOrderMaxDelayInSeconds: 0
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
    transformation: {
      name: 'Transformation'
      properties: {
        streamingUnits: numberOfStreamingUnits
        query: 'SELECT\r\n    *\r\nINTO\r\n    [YourOutputAlias]\r\nFROM\r\n    [YourInputAlias]'
      }
    }
  }
}
