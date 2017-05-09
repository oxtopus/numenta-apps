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

/*
  * Default Data factory used to create standard CoreDatabase Objects
  */
class CoreDataFactoryImpl: CoreDataFactory {
    
    func createAnnotation(_ cursor: FMResultSet!) -> Annotation! {
        return Annotation(cursor: cursor)
    }

    func createAnnotation(_ annotationId: String!, timestamp: Int64, created: Int64, device: String!, user: String!, instanceId: String!, message: String!, data: String!) -> Annotation! {
          return Annotation(annotationId: annotationId, timestamp: timestamp, created: created, device: device, user: user, instanceId: instanceId, message: message, data: data)
    }

    func createMetric(_ cursor: FMResultSet!) -> Metric! {
        return Metric(cursor)
    }

    func createMetric(_ metricId: String!, name: String!, instanceId: String!, serverName: String!, lastRowId: Int32, parameters: JSON!) -> Metric! {
         return Metric(metricId: metricId, name: name, instanceId: instanceId!, serverName: serverName, lastRowId: lastRowId, parameters: parameters)
    }

    func createMetricData(_ cursor: FMResultSet!) -> MetricData! {
        return MetricData(cursor: cursor)
    }

    func createMetricData( _ metricId: String!, timestamp: Int64, metricValue: Float, anomalyScore: Float, rowid: Int64) -> MetricData! {
        return MetricData(metricId: metricId, timestamp: timestamp, metricValue: metricValue , anomalyScore: anomalyScore, rowid: rowid)
    }

    func createInstance( _ id: String!, name: String!, namespace: String!, location: String!, message: String!, status: Int32) -> Instance! {
      return Instance(id: id, name: name, namespace: namespace, location: location!, message: message, status: status)
    }

    func createInstanceData(_ cursor: FMResultSet!) -> InstanceData! {
        return InstanceData(cursor: cursor)
    }

    func createInstanceData(_ instanceId: String!,  aggregation: AggregationType!, timestamp: Int64, anomalyScore: Float) -> InstanceData! {
      return InstanceData(instanceId: instanceId , aggregation: aggregation.minutes(), timestamp: timestamp, anomalyScore: anomalyScore)
    }

    func createNotification(_ cursor: FMResultSet!) -> Notification! {
        return Notification(cursor: cursor)
    }

    func createNotification(_ notificationId: String!, metricId: String!, timestamp: Int64, read: Bool, description: String!) -> Notification! {
           return Notification(notificationId: notificationId, metricId: metricId, timestamp: timestamp, read: read, description: description)
    }
}
