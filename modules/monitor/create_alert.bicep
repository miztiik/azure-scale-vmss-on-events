param deploymentParams object
param tags object = resourceGroup().tags

param alertRuleName string
param alertRuleDisplayName string
param alertRuleDescription string
param scope_workspaceId_1 string // log analytics workspace resource id
param alertRuleSeverity int
param windowSize string
param evaluationFrequency string
param autoMitigate bool
param kql_alert_query string


resource rule 'Microsoft.Insights/scheduledQueryRules@2022-08-01-preview' = {
  location: deploymentParams.location
  tags: tags
  name: alertRuleName
  properties: {
    description: alertRuleDescription
    displayName: alertRuleDisplayName
    enabled: true
    scopes: [
      scope_workspaceId_1
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    windowSize: windowSize
    evaluationFrequency: evaluationFrequency
    severity: alertRuleSeverity
    autoMitigate: autoMitigate
    criteria: {
      allOf: [
          {
              query: kql_alert_query
              timeAggregation: 'Count'
              dimensions: []
              operator: 'GreaterThan'
              threshold: 1
              failingPeriods: {
                  numberOfEvaluationPeriods: 1
                  minFailingPeriodsToAlert: 1
              }
          }
      ]
    }

  }
}
