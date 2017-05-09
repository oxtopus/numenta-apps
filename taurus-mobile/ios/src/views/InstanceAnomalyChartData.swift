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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



  /** Holds the date for the chart
  */
class InstanceAnomalyChartData : AnomalyChartData {
    var ticker : String? = nil
    var instanceId : String
    var data : [(Int64, Double)]?
    var rank: Float = 0
    var aggregation : AggregationType
    var name : String = ""
    var endDate : Int64 = 0
    var metrics :[Metric]?
    var anomalousMetrics : MetricType = MetricType()
    var modified: Bool = false
    var lastDBTimestamp : Int64 = 0
    
    init(instanceId: String, aggregation: AggregationType){
        self.instanceId = instanceId
        self.aggregation = aggregation
    }
    
    /**
    * - returns: true if more than 1 data object
    */
    func hasData()->Bool {
        if (data != nil){
            if (data?.count>0){
                return true
            }
        }
        return false
    }
    
    /**
    * - returns: Display Name
    */
    func getName()->String{
        return self.name
    }
    
    /**
    * Aggregated metric data, 
    * - returns: data array
    */
    func getData()->[(Int64, Double)]?{
        return self.data
    }
    
    /**
    * - returns: Aggregation used for data
    */
    func getAggregation()->AggregationType{
        return self.aggregation
    }
    
    /**
    * Load metric data from the database
    *
    * - results: return true for success
    */
    func load()->Bool{
        let db = TaurusApplication.getTaurusDatabase()
        
        self.name = db.getServerName(instanceId)
        self.ticker = db.getTickerSymbol (instanceId)
        self.metrics = db.getMetricsByInstanceId(instanceId)
        
        let timestamp = db.getLastTimestamp()
        if self.endDate <= 0 {
            endDate = timestamp
        }

        let  limit = TaurusApplication.getTotalBarsOnChart()
        // Make sure to load 7 days worth of data to accommodate collapsed view
        let  startDate : Int64 = endDate - Int64(7) * Int64(limit) * aggregation.milliseconds()
        // Query database for aggregated values
        let anomalies :[Int64:AnomalyValue]? = db.getInstanceData(instanceId, from: startDate, to: endDate)
        var changed = true
        // Extract anomaly scores
        var scores = [(Int64,Double)]()
        if anomalies == nil{
            return  false
        }
        
        for (key, value) in anomalies!{
            scores.append((key,Double(value.anomaly)))
        }
        
        
        
        // FIXME check if it would be easier to keep list sorted
        scores.sort {
            return $0.0 < $1.0
        }
        
       
        // Check if anything changed
        // fixmeabs(
        changed = true
        
        self.data = scores
       

        // Rank data based on the last bars if changed
       if (timestamp != lastDBTimestamp || changed) {
            lastDBTimestamp = timestamp
            // Get last "limit" bars
            let data :[Int64:AnomalyValue]? = db.getInstanceData(instanceId, from: lastDBTimestamp - Int64(limit) * aggregation.milliseconds(), to: lastDBTimestamp)
            // Sort and Truncate results
            let sortedAnomalies = data?.sorted {
                $0.0 > $1.0
            }.prefix(limit)

            rank = 0
            anomalousMetrics.rawValue = 0
            for (_, value) in sortedAnomalies! {
                rank += Float(DataUtils.calculateSortRank ((Double(abs(value.anomaly)))))
                anomalousMetrics.insert(value.metricMask)
            }

            if (anomalousMetrics.rawValue != 0) {
                if (anomalousMetrics.contains( MetricType.StockPrice) || anomalousMetrics.contains( MetricType.StockVolume)) {
                    rank += Float(DataUtils.RED_SORT_FLOOR*1000.0)
                }
                
                if (anomalousMetrics.contains( MetricType.TwitterVolume)) {
                    rank += Float(DataUtils.RED_SORT_FLOOR*100.0)
                }
            }
        }
        self.modified = false
        
        return changed
    }
    
    /**
    * remove data
    */
    func clear(){
        data = nil
        rank = 0
        modified = true
    }
    
    /**
    * Load data up to this date
    *
    * - parameter endDate: the endDate to set
    */
    func setEndDate( _ endDate : Date){
        
      //  print (endDate)
        let secsSince1970 : Double = endDate.timeIntervalSince1970
        self.endDate = Int64(secsSince1970*1000)
    }
    
    /**
    * current end date
    *
    * -returns: the endDate
    */
    func getEndDate()->Date?{
        if (self.endDate==0){
            return nil
        }    
        return Date(timeIntervalSince1970: Double(endDate)/1000.0)
    }
    
    /**
    * Instance or Metric ID represented by this data
    */
    func getId()->String{
        return self.instanceId
    }
    
    /**
    * Get Metric Unit if available
    */
    func getUnit()->String?{
        return nil
    }
    
    /**
    * This chart data type, "I" for instance or "M" for metric
    */
    func getType()->Character{
        return "I"
    }
    
    /**
    * Get all timestamps with annotations
    */
    func getAnnotations() ->[Int64]?{
        return nil
    }
    
    /**
    * Return the overall rank for the data represented by this class.
    * Usually the rank is calculated as the sum of all anomaly score values
    */
    func getRank()->Float{
        return rank
    }

    func getCollapsedData()->[(Int64, Double)]{
        let marketCalendar = TaurusApplication.marketCalendar
        var marketClosed = false
        var collapsedData = [(Int64, Double)]()

        if let data = self.data {
            for val in data {
                let time = val.0 + DataUtils.METRIC_DATA_INTERVAL
                
                if ( marketCalendar.isOpen( time) == false){
                    marketClosed = true
                    continue
                }
                
                if (marketClosed){
                    collapsedData.append( (0,0) )
                    marketClosed = false
                }
                collapsedData.append ( val )
            }
        }
        
        if (marketClosed){
            collapsedData.append( (0,0) )
          
        }
        return collapsedData
        
    }
    
}
