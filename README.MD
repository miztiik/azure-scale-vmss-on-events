# Effortlessly Scale Your Azure VM Scale Sets in Response to Events

At Mystique Unicorn, the developers have adopted the event-driven architectural pattern for their application, which enables them to process streaming data. Specifically, their physical stores will be sending a continuous stream of sales and inventory related events to a central location. Multiple downstream systems will then consume these events. To ensure scalability, the team intends to utilize Azure VM Scale Sets to expand their event consumers whenever the Azure Storage queue length increases.

Given their interest in leveraging Azure's event-driven capabilities, the developers are seeking guidance on how to begin implementing these features. 

## 🎯 Solutions

To take advantage of Azure's event-driven capabilities and achieve autoscaling, we can configure [Azure VM Scale Sets (VMSS)][1] to dynamically increase or decrease the number of VMs based on specific events. In this case, we can scale the VMSS based on the length of the [Storage Queue Level][2]. It's worth noting that, at the moment (as of Q2-2023), Azure only supports granularity at the Storage Account level, rather than at the individual Storage Queue level. As a result, to make this approach work, we would need to limit the storage account to a single queue. Assuming that this limitation is acceptable, we can proceed with this strategy.

![Miztiik Automaton: Auto Scaling Azure VM(ScaleSets) in response to events](images/miztiik_automation_azure_vm_to_storage_queue_architecture_0001.png)

While building this solution, I have found anamolies that created challenges in implementing this solution. I have documented them in the [Anamolies](#-anamolies) section. 

During the process of building this solution, I have encountered anomalies that have posed challenges to the implementation. These anomalies have been documented in the [Anamolies](#-anamolies) section.

## 📝 Anamolies

  Before we proceed to examine the anomalies, it's important to note that there are currently a few messages present in the queue. Additionally, a producer is continuously adding messages to the queue over a period of time. As a result, any query made to determine the queue length should return a non-zero value.

  ![Miztiik Automaton: Auto Scaling Azure VM(ScaleSets) in response to events](images/miztiik_automation_azure_scale_vmss_on_events_architecture_002.png)
      

   - **Azure Monitor Portal** - My own testing shows that the metric is not updated even after every few hours
    ![Miztiik Automaton: Auto Scaling Azure VM(ScaleSets) in response to events](images/miztiik_automation_azure_scale_vmss_on_events_architecture_003.png)
   - **Azure Monitor Storage Account Metrics** - The granularity of Storage Queue Metrics is at storage account level and not at individual resource level <sup>[3],[4],[5]</sup> as a metric. 
   - **Azure Monitor Metric Update Frequency** - `QueueMessageCount` is [platform metric][5]. The update frequency is supposedly `1` minute<sup>[6]</sup>. 
   
        _Excerpt from the [docs][5]_
    
        >This article is a complete list of all platform (that is, automatically collected) metrics currently available with the consolidated metric pipeline in Azure Monitor.

        _Excerpt from the [docs][6]_
    
        >Platform metrics are collected from Azure resources at **one-minute** frequency unless specified otherwise in the metric's definition.

      The best practices for monitoring [Azure Queue Storage][7] informs that this is metric is refreshed daily.

        _Excerpt from the [docs][7]_
    
        >You can monitor the message count for all queues in a storage account by using the QueueMessageCount metric. This metric is **refreshed daily**.
   
   - **Azure SDK to Query Queue Metrics from Azure Monitor** - Querying the Queue Metrics directly using the SDK also does not reflect the facts. I used the python<sup>[8],[9]</sup> SDK and wrote a script to query the metrics. The metric is not updated even after every few hours.

      ```python
      # export PYTHONWARNINGS="ignore:Unverified HTTPS request"
      # pip install azure-mgmt-monitor==6.0.0
      # pip install azure-monitor-query=1.1.1
      import os
      from datetime import timedelta, datetime
      from azure.identity import DefaultAzureCredential
      from azure.mgmt.monitor import MonitorManagementClient
      from azure.monitor.query import LogsQueryClient, MetricsQueryClient, MetricsQueryClient, MetricAggregationType


      subscription_id = "1axxxx9e3"
      resource_group = "Miztiik_Enterprises_scale_vmss_on_events_011"
      storage_account = "warehouseghv6kv011"
      queue_service = "store-events-q-011"

      metrics_uri = (
          f"subscriptions/{subscription_id}"
          f"/resourceGroups/{resource_group}"
          f"/providers/Microsoft.Storage"
          f"/storageAccounts/{storage_account}"
          f"/queueServices/{queue_service}"
      )

      credential = DefaultAzureCredential()

      query_client = MetricsQueryClient(credential)
      start_time = datetime(2023, 4, 19)
      duration = timedelta(days=2)


      response = query_client.query_resource(
          metrics_uri,
          metric_names=["QueueMessageCount"],
          timespan=(start_time, duration)
          )
      
      print(f"QueueMessageCount: {response.metrics._metric_names['QueueMessageCount']} TimePeriod: {response.timespan} Granularity: {response.granularity} ")
      ```
      _Output_

      ```bash
      QueueMessageCount: 0 TimePeriod: 2023-04-19T00:00:00Z/2023-04-21T00:00:00Z Granularity: 1:00:00
      ```

   - **Azure SDK to Query Queue Metrics from Queue Properties** - I have tested the queue length update frequency by querying the queue message count from queue properties using [Python SDK][10]. This method seems to deliver much better results.

      ```python
      import os
      import time
      from azure.identity import DefaultAzureCredential
      from azure.storage.queue import QueueServiceClient

      Q_NAME="store-events-q-011"
      SA_NAME = os.getenv("SA_NAME", "warehouseghv6kv011")
      Q_SVC_ACCOUNT_URL=f"https://{SA_NAME}.queue.core.windows.net"

      credential = DefaultAzureCredential(logging_enable=False)
      q_svc_client = QueueServiceClient(Q_SVC_ACCOUNT_URL, credential=credential)

      q_client = q_svc_client.get_queue_client(Q_NAME)

      for num in range(1, 11):
          properties = q_client.get_queue_properties()
          count = properties.approximate_message_count
          print("Current Message count: " + str(count))
          time.sleep(10)
      ```
      _Output: As we can observe the # of messages keep increasing every `10` seconds. That means the properties is clearly updated much more frequently. As a future exercise, i will try to verify it with actual count of messages in queue._
      ```bash
      Current Message count: 2973
      Current Message count: 2977
      Current Message count: 2981
      Current Message count: 2985
      Current Message count: 2989
      Current Message count: 2993
      Current Message count: 2997
      Current Message count: 3001
      Current Message count: 3005
      Current Message count: 3009
      ```

   - **Azure Portal - Strange Place to look for consistencies** - If you navigate to the Azure Storage Queue Resource Portal Page, Surprisingly you will find the queue length being updated in the properties field.

      ![Miztiik Automaton: Auto Scaling Azure VM(ScaleSets) in response to events](images/miztiik_automation_azure_scale_vmss_on_events_architecture_005.png)

   - **Azure Portal - Diagnostics for Storage Queue** - If you enable diagnostic logging for your Stroage Account - Queue, it does show the transctions of message ingests.

      ![Miztiik Automaton: Auto Scaling Azure VM(ScaleSets) in response to events](images/miztiik_automation_azure_scale_vmss_on_events_architecture_004.png)


      
## 📒 Conclusion
  Based on current information and research, it appears that the `QueueMessageCount` metric in Azure is not consistently updated, and its frequency cannot be relied upon. This issue has been highlighted by the community on [StackOverflow][11]. As a result, the best approach to monitor the queue length is to use the Azure SDK to directly query the queue. One potential solution could be to use Azure Functions to query the queue length and dynamically scale the VMSS accordingly.

  In addition, it's worth considering the specific requirements of your application when choosing between Azure Storage Queue and Azure Service Bus. If you need reliable, granular, and frequently updated metrics for your queue, then Azure Service Bus may be the more suitable option.

## 🧹 CleanUp

If you want to destroy all the resources created by the stack, Execute the below command to delete the stack, or _you can delete the stack from console as well_

- Resources created during this demo
- _Any other custom resources, you have created for this demo_

```bash
# Delete from resource group
az group delete --name Miztiik_Enterprises_xxx --yes
# Follow any on-screen prompt
```

This is not an exhaustive list, please carry out other necessary steps as maybe applicable to your needs.

## 📌 Who is using this

This repository aims to show how to use Azure with Iac(Bicep) to new developers, Solution Architects & Ops Engineers in Azure.

### 💡 Help/Suggestions or 🐛 Bugs

Thank you for your interest in contributing to our project. Whether it is a bug report, new feature, correction, or additional documentation or solutions, we greatly value feedback and contributions from our community. [Start here](/issues)

### 👋 Buy me a coffee

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Q5Q41QDGK) Buy me a [coffee ☕][900].

### 📚 References


1. [Azure Docs: Autoscale for VMSS][1]
1. [Azure Docs: Custom Autoscale for VMSS with Resource Metrics][2]
1. [Azure Docs: Monitoring Azure Queue Storage][3]
1. [Azure Docs: Queue Storage monitoring data reference][4]
1. [Azure Docs: Supported metrics with Azure Monitor - Queue Storage][5]
1. [Azure Docs: Supported metrics with Azure Monitor - Queue Storage Data Collection][6]
1. [Azure Docs: Best practices for monitoring Azure Queue Storage][7]
1. [Azure Docs: Azure Monitoring libraries for python][8]
1. [Azure Docs: Azure Monitor Query client library for Python][9]
1. [Azure Docs: Azure Monitor Query client library for Python][10]
1. [StackOverflow: How frequently are the Azure Storage Queue metrics updated][11]
1. [Azure Docs: Configure pythong logging in the Azure libraries][9]


### 🏷️ Metadata

![miztiik-success-green](https://img.shields.io/badge/Miztiik:Automation:Level-300-purple)

**Level**: 300

[1]: https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-autoscale-overview
[2]: https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-autoscale-overview#metric-sources
[3]: https://learn.microsoft.com/en-us/azure/storage/queues/monitor-queue-storage
[4]: https://learn.microsoft.com/en-us/azure/storage/queues/monitor-queue-storage-reference
[5]: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-supported#microsoftstoragestorageaccountsqueueservices
[6]: https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-platform-metrics#data-collection
[7]: https://learn.microsoft.com/en-us/azure/storage/queues/queues-storage-monitoring-scenarios
[8]: https://learn.microsoft.com/en-us/python/api/overview/azure/monitor?view=azure-python
[9]: https://learn.microsoft.com/en-us/python/api/overview/azure/monitor-query-readme?view=azure-python#metrics-query
[10]: https://learn.microsoft.com/en-us/azure/storage/queues/storage-python-how-to-use-queue-storage#get-the-queue-length
[11]: https://stackoverflow.com/questions/67560805/how-frequently-are-the-azure-storage-queue-metrics-updated

[100]: https://www.udemy.com/course/aws-cloud-security/?referralCode=B7F1B6C78B45ADAF77A9
[101]: https://www.udemy.com/course/aws-cloud-security-proactive-way/?referralCode=71DC542AD4481309A441
[102]: https://www.udemy.com/course/aws-cloud-development-kit-from-beginner-to-professional/?referralCode=E15D7FB64E417C547579
[103]: https://www.udemy.com/course/aws-cloudformation-basics?referralCode=93AD3B1530BC871093D6
[899]: https://www.udemy.com/user/n-kumar/
[900]: https://ko-fi.com/miztiik
[901]: https://ko-fi.com/Q5Q41QDGK