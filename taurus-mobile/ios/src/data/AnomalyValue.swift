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
  * Represents an anomaly value composed of the aggregated anomaly value and a mask indicating the
  * metric types with anomalous values if any.
  *
  * @see com.numenta.taurus.metric.MetricType#flag()
  * @see com.numenta.taurus.metric.MetricType#fromMask(int)
  */
  
class AnomalyValue  {
    var anomaly: Float
    var metricMask: MetricType

    init(anomaly: Float, metricMask: MetricType) {
        self.anomaly = anomaly
        self.metricMask = metricMask
    }

    func equals( _ o: AnyObject!) -> Bool {
        let that: AnomalyValue! = o as! AnomalyValue
        
        if (that == nil){
            return false
        }
        
        if that.anomaly != anomaly {
            return false
        }
        
        return metricMask == that.metricMask
    }

}
