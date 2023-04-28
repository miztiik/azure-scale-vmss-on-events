param deploymentParams object
param logAnalyticsWorkspaceParams object
param tags object = resourceGroup().tags

// Create the LogAnalytics Workspace Pay-As-You-Go Tier
resource r_logAnalyticsPayGWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = if (logAnalyticsWorkspaceParams.commitTier == false) {
  name: '${logAnalyticsWorkspaceParams.workspaceName}-payGTier-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  properties: {
    retentionInDays: logAnalyticsWorkspaceParams.retentionInDays
    sku: {
      name: 'PerGB2018'
    }
    workspaceCapping: {
      dailyQuotaGb: logAnalyticsWorkspaceParams.dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}


// Create the LogAnalytics Workspace Committment Tier
resource r_logAnalyticsCommitTierWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (logAnalyticsWorkspaceParams.commitTier == true){
  name: '${logAnalyticsWorkspaceParams.workspaceName}-commitTier-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  properties: {
    sku: {
      name: 'CapacityReservation'
      capacityReservationLevel: 100
    }
  }
}

// az monitor log-analytics workspace table list --resource-group Miztiik_Enterprises_Log_Monitor_002 --workspace-name lumberyard-payGTier-002
resource r_storeEventsCustomTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent:r_logAnalyticsPayGWorkspace
  name: '${logAnalyticsWorkspaceParams.storeEventsCustomTableName}${deploymentParams.global_uniqueness}_CL'
  // tags: tags
  properties: {
    // plan: 'Basic'
    /*
    Apparently Basic plan does not support custom tables, ARM throws an error. Couldn't find the actual doc sayin it
    https://learn.microsoft.com/en-us/azure/azure-monitor/logs/basic-logs-configure?tabs=portal-1
    */
    plan: 'Analytics'
    retentionInDays: -1
    schema: {
      description:'Store order events custom table'
      displayName:'DOESNT-SEEM-TO-WORK-STORE-EVENTS'
      name: '${logAnalyticsWorkspaceParams.storeEventsCustomTableName}${deploymentParams.global_uniqueness}_CL'
      columns: [
        {
          name: 'TimeGenerated'
          type: 'datetime'
        }
        {
          name: 'RawData'
          type: 'string'
        }
        {
          name: 'request_id'
          type: 'string'
        }
        {
          name: 'event_type'
          type: 'string'
        }
        {
          name: 'store_id'
          displayName: 'store_id'
          description: 'The Id of the store placing the Order'
          type: 'int'
        }
        {
          name: 'cust_id'
          type: 'int'
        }
        {
          name: 'category'
          type: 'string'
        }
        {
          name: 'sku'
          type: 'int'
        }
        {
          name: 'price'
          type: 'real'
        }
        {
          name: 'qty'
          type: 'int'
        }
        {
          name: 'discount'
          type: 'real'
        }
        {
          name: 'gift_wrap'
          type: 'boolean'
        }
        {
          name: 'variant'
          description: 'Product Variety'
          type: 'string'
        }
        {
          name: 'priority_shipping'
          description: 'Priority Shipping requested'
          type: 'boolean'
        }
        {
          name: 'contact_me'
          description: 'Miztiik Automation Brand Experience Store'
          displayName: 'contact_me'
          type: 'string'
        }
      ]
    }
  }
}

resource r_automationEventsCustomTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent:r_logAnalyticsPayGWorkspace
  name: '${logAnalyticsWorkspaceParams.automationEventsCustomTableName}${deploymentParams.global_uniqueness}_CL'
  properties: {
    // plan: 'Basic'
    /*
    Apparently Basic plan does not support custom tables, ARM throws an error. Couldn't find the actual doc sayin it
    https://learn.microsoft.com/en-us/azure/azure-monitor/logs/basic-logs-configure?tabs=portal-1
    */
    plan: 'Analytics'
    retentionInDays: -1
    schema: {
      description:'Miztiik Automation Events'
      displayName:'DOESNT-SEEM-TO-WORK-AUTOMATION-EVENTS'
      name: '${logAnalyticsWorkspaceParams.automationEventsCustomTableName}${deploymentParams.global_uniqueness}_CL'
      columns: [
        {
          name: 'TimeGenerated'
          type: 'datetime'
        }
        {
          name: 'RawData'
          type: 'string'
        }
        {
          name: 'request_id'
          type: 'string'
        }
      ]

    }
  }
}

/*

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 7
    partitionCount: 1
  }
}
*/

output logAnalyticsPayGWorkspaceId string = r_logAnalyticsPayGWorkspace.id
output logAnalyticsPayGWorkspaceName string = r_logAnalyticsPayGWorkspace.name
output logAnalyticsCommitTierWorkspaceId string = r_logAnalyticsCommitTierWorkspace.id


output storeEventsCustomTableNamePrefix string = '${logAnalyticsWorkspaceParams.storeEventsCustomTableName}${deploymentParams.global_uniqueness}'
output storeEventsCustomTableName string = r_storeEventsCustomTable.name

output automationEventsCustomTableNamePrefix string = '${logAnalyticsWorkspaceParams.automationEventsCustomTableName}${deploymentParams.global_uniqueness}'
output automationEventsCustomTableName string = r_automationEventsCustomTable.name

