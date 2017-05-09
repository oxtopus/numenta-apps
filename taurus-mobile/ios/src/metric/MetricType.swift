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


import Foundation



/** Holds a set of Metrics
*/
struct MetricType : OptionSet {
    var rawValue: Int
    
    static let None         = MetricType(rawValue: 0)
    static let StockPrice  = MetricType(rawValue: 1 << 0)
    static let StockVolume = MetricType(rawValue: 1 << 1)
    static let TwitterVolume  = MetricType(rawValue: 1 << 2)
    static let NewsVolume  = MetricType(rawValue: 1 << 3)


    /** Returns the metricType for a string
        - parameter key:
        - returns : metricType
    */
    static func enumForKey(_ key:String)->MetricType{
        switch (key){
            case "StockPrice":
                return MetricType.StockPrice
        case "StockVolume":
            return MetricType.StockVolume
        case "TwitterVolume":
            return MetricType.TwitterVolume
        case "NewsVolume":
            return MetricType.NewsVolume
        
        default:
            return MetricType.None
        }
       
    }
}
