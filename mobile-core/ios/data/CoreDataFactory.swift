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
* Factory used to create Core Database objects. It should be supplied by applications who need to
* extend any of the {@link CoreDatabase} objects.
*/
protocol CoreDataFactory {
    func createAnnotation(_ cursor: FMResultSet!) -> Annotation!
    func createAnnotation(_ annotationId: String!, timestamp: Int64, created: Int64, device: String!, user: String!, instanceId: String!, message: String!, data: String!) -> Annotation!
    func createMetric(_ cursor: FMResultSet!) -> Metric!
    func createMetric(_ metricId: String!, name: String!, instanceId: String!, serverName: String!, lastRowId: Int32, parameters: JSON!) -> Metric!
    func createMetricData(_ cursor: FMResultSet!) -> MetricData!
    func createMetricData(_ metricId: String!, timestamp: Int64, metricValue: Float, anomalyScore: Float, rowid: Int64) -> MetricData!
    func createInstance(_ id: String!, name: String!, namespace: String!, location: String!, message: String!, status: Int32) -> Instance!
    func createInstanceData(_ cursor: FMResultSet!) -> InstanceData!
    func createInstanceData(_ instanceId: String!, aggregation: AggregationType!, timestamp: Int64, anomalyScore: Float) -> InstanceData!
    func createNotification(_ cursor: FMResultSet!) -> Notification!
    func createNotification(_ notificationId: String!, metricId: String!, timestamp: Int64, read: Bool, description: String!) -> Notification!
}
