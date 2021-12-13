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

resource streamAnalyticsJob 'Microsoft.StreamAnalytics/streamingjobs@2020-03-01' = {
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
        query: 'SELECT\n    System.TimeStamp() as AggregationTime,\n    UserId,\n    COUNT(*) AS eventCount,\n    SUM(CAST(udf.parseJson(backendEventHub.EventPayload).amount as bigint)) as totalAmount\nINTO\n    evtHubSink\nFROM\n    backendEventHub TIMESTAMP BY [Timestamp]\nWHERE Event=\'WITHDRAWAL\'\nGROUP BY UserId, TumblingWindow(second, 60)'
      }
    }
  }
}
/* Sample query aggregating the amount

SELECT
    System.TimeStamp() as AggregationTime,
    UserId,
    COUNT(*) AS eventCount,
    SUM(CAST(udf.parseJson(backendEventHub.EventPayload).amount as bigint)) as totalAmount
INTO
    evtHubSink
FROM
    backendEventHub TIMESTAMP BY [Timestamp]
WHERE Event='WITHDRAWAL'
GROUP BY UserId, TumblingWindow(second, 60)
*/
