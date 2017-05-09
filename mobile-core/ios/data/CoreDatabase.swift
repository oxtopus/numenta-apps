  /*
  * Numenta Platform for Intelligent Computing (NuPIC)
  * Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
  * Numenta, Inc. a separate commercial license for this software code, the
  * following terms and conditions apply:
  *
  * This program is free software: you can redistribute it and/or modify
  * it under the terms of the GNU General Public License version 3 as
  * published by the Free Software Foundation.
  *
  * This program is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  * See the GNU General Public License for more details.
  *
  * You should have received a copy of the GNU General Public License
  * along with this program.  If not, see http://www.gnu.org/licenses.
  *
  * http://numenta.org/licenses/
 *
 */

/**
    Database protocol.
  */
protocol CoreDatabase {
    func getVersion() -> Int
    func getFileName() -> String!
    func getServerName(_ _instanceId: String!) -> String!
    
    func getReadableDatabase() -> FMDatabase!
    func getWritableDatabase() -> FMDatabase!
    
    func getDataFactory() -> CoreDataFactory!
    func getLastTimestamp() -> Int64
    func deleteOldRecords() -> Int32
    func deleteAll()
    
    // Metrics
    func addMetric(_ metric: Metric!) -> Int64
    func getAllMetrics() -> [Metric]!
    func getMetric(_ id: String!) -> Metric!
    func updateMetric(_ metric: Metric!) -> Bool
    func deleteMetric(_ id: String!) -> Int32
    func getMetricsByInstanceId(_ instanceId: String!) -> [Metric]!
    
    // Metric Data
    func addMetricDataBatch(_ _batch: [MetricData]!) -> Bool
    func getMetricData(_ metricId: String!, columns: [String]!, from: Date!, to: Date!, anomalyScore: Float, limit: Int32) -> FMResultSet!
    
    // Instance Data
    func addInstanceDataBatch(_ batch: [InstanceData]!) -> Bool
    func getInstanceData( _ instanceId: String!, columns: [String]!, aggregation: AggregationType!, from: Date!, to: Date!, anomalyScore: Float, limit: Int32) -> FMResultSet!
    func updateInstanceData(_ _instanceData: InstanceData!) -> Bool

    // Instances
    func getAllInstances() -> Set<String>!
    func deleteInstance(_ _instance: String!)
    func deleteInstanceData(_ _instanceId: String!)
   
    // Notifications - NOT USED IN TAURUS SO FAR
    func addNotification(_ notificationId: String!, metricId: String!, timestamp: Int64, description: String!) -> Int64
    func getAllNotifications() -> [Notification]!
    func getNotificationByLocalId(_ localId: Int32) -> Notification!
    func getUnreadNotificationCount() -> Int32
    func getNotificationCount() -> Int32
    func markNotificationRead(_ notificationId: Int32) -> Bool
    func deleteNotification(_ localId: Int32) -> Int32
    func deleteAllNotifications() -> Int32
    
    // Annotations - NOT USED IN TAURUS SO FAR
    func addAnnotation(_ annotation: Annotation!) -> Int64
    func getAllAnnotations() -> [Annotation]!
    func getAnnotation(_ id: String!) -> Annotation!
    func getAnnotations(_ server: String!, from: Date!, to: Date!) -> [Annotation]!
    func deleteAnnotation(_ id: String!) -> Int32
    func deleteAnnotationByInstanceId(_ instanceId: String!) -> Int32
}
