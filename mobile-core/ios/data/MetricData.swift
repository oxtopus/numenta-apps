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

open class MetricData {
    //  /** Database Table name */
    static let TABLE_NAME: String! = "metric_data"
    var metricId: String!
    var timestamp: Int64
    var metricValue: Float
    var anomalyScore: Float
    var rowid: Int64

    init(cursor: FMResultSet!) {
        self.metricId = cursor.string(forColumn: "metric_id")
        self.metricValue = Float(cursor.double(forColumn: "metric_value"))
        self.anomalyScore = Float(cursor.double(forColumn: "anomaly_score"))
        self.timestamp = cursor.longLongInt(forColumn: "timestamp")
        self.rowid = cursor.longLongInt(forColumn: "rowid")
    }

    init(metricId: String!, timestamp: Int64, metricValue: Float, anomalyScore: Float, rowid: Int64) {
        self.metricId = metricId
        self.timestamp = timestamp
        self.metricValue = metricValue
        self.anomalyScore = anomalyScore
        self.rowid = rowid
    }

    init() {
         metricId = ""
         timestamp = 0
         metricValue = 0
         anomalyScore = 0
         rowid = -1
    }

    func getValues() -> Dictionary<String, AnyObject>! {
        var values = Dictionary<String, AnyObject>()
        values["metric_id"] = self.metricId as AnyObject
        values["metric_value"] = NSNumber(value: self.metricValue as Float)
        values["anomaly_score"] = NSNumber(value: self.anomalyScore as Float)
        values["timestamp"] = NSNumber(value: self.timestamp as Int64)
        values["rowid"] = NSNumber(value: self.rowid as Int64)
        return values
    }

    func getMetricId() -> String! {
        return self.metricId
    }

    func getTimestamp() -> Int64 {
        return self.timestamp
    }

    func getMetricValue() -> Float {
        return self.metricValue
    }

    func getAnomalyScore() -> Float {
        return self.anomalyScore
    }

    func getRowid() -> Int64 {
        return self.rowid
    }

    func setMetricId(_ _metricId: String!) {
        self.metricId = _metricId
    }

    func setTimestamp(_ _timestamp: Int64) {
        self.timestamp = _timestamp
    }
}
