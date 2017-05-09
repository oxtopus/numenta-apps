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
import Foundation

class AggregationType{
 
    /** Hourly aggregation into 5 minutes buckets */
    static var Hour = AggregationType(period: 5)
    
    /** Half day aggregation into 30 minutes buckets */
    static var HalfDay = AggregationType(period: 30)
    
    /** Daily aggregations into 60 minutes buckets */
    static var Day  = AggregationType(period: 60)
    
    /** Weekly aggregations into 8 hours buckets */
    static var Week  = AggregationType(period: 480)

    var    period: Int32;
    
    /**
    * Returns the closest {@link AggregationType} matching the given interval
    *
    * @param interval The interval value in milliseconds
    * @return The {@link AggregationType} that best matches the interval.
    */
    func AggregationTypefromInterval(_ interval:Int64)->AggregationType {
        
        if (interval <= AggregationType.Hour.milliseconds()) {
                return AggregationType.Hour
            } else if (interval <= AggregationType.HalfDay.milliseconds()) {
                return AggregationType.HalfDay
            } else if (interval <= AggregationType.Day.milliseconds()) {
                return AggregationType.Day;
            } else {
                return AggregationType.Week;
            }
    }
    
    init( period: Int32) {
     self.period = period;
    }
    
    /**
    * Aggregation period in milliseconds
    */
    func milliseconds()->Int64 {
        return Int64( 60 * 1000) * Int64(period);
    }
    
    /**
    * Aggregation period in seconds
    */
    func seconds()->Int32 {
        return period * 60;
    }
    
    /**
    * Aggregation period in minute
    */
    func  minutes()->Int32 {
        return period;
    }
 
}
