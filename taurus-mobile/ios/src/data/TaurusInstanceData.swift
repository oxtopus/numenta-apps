// Numenta Platform for Intelligent Computing (NuPIC)
// Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
// Numenta, Inc. a separate commercial license for this software code, the
// following terms and conditions apply:
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero Public License version 3 as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Affero Public License for more details.
//
// You should have received a copy of the GNU Affero Public License
// along with this program.  If not, see http://www.gnu.org/licenses.
//
// http://numenta.org/licenses/

/**
* Represents taurus instance data composed of aggregated anomaly value and a mask indicating the
* metric types with anomalous values if any.
*/
class TaurusInstanceData: InstanceData {
    //  // The metrics with anomalies.
    var metricMask: MetricType = MetricType()

    override init(cursor: FMResultSet!) {
         self.metricMask.rawValue = Int(cursor.int(forColumn: "metric_mask"))
        super.init(cursor: cursor )
       
    }

    override func getValues()-> Dictionary<String, AnyObject>! {
        var values:  Dictionary<String, AnyObject> = super.getValues()
        values["metric_mask"] = NSNumber(value: metricMask.rawValue as Int)
        return values
    }

    init(instanceId: String!, aggregation: Int32, timestamp: Int64, anomalyScore: Float, metricMask: MetricType!) {
        
        self.metricMask = metricMask
        super.init(instanceId: instanceId, aggregation:  aggregation, timestamp: timestamp, anomalyScore:anomalyScore)
       
    }

    init(instanceId: String!, aggregation: Int32, timestamp: Int64, anomalyScore: Float, metricMask: MetricType) {
        self.metricMask = metricMask
        
        super.init(instanceId : instanceId, aggregation: aggregation, timestamp : timestamp, anomalyScore : anomalyScore)
    }

    func getMetricMask() -> MetricType {
        return self.metricMask
    }
}
