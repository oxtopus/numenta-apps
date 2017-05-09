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
 
  /** dictionary wrapper to allow passing of dictionarys by reference instead of value
  */
  class InstanceCacheEntry{
    var data = Dictionary<Int64, AnomalyValue>()
  }
  
class TaurusDatabase: CoreDatabaseImpl,TaurusDBProtocol {
    let TAURUS_DATABASE_VERSION: Int32 = 32
    var firstTimestamp : Int64 = 0
    var lastUpdated: Int64 = 0
    
    var  instanceDataCache = [String :  InstanceCacheEntry ] ()
    
    static let INSTANCEDATALOADED : String = "com.numenta.taurusdatabase.instancedataloaded"
  
    /**
        - parameter dataFactory: used to creat DB objects
    */
    override init(dataFactory : CoreDataFactory){
        super.init(dataFactory : dataFactory)
        
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: DataSyncService.REFRESH_STATE_EVENT), object: nil, queue: nil, using: {
            [unowned self] note in
            
            let property = note.object as! Bool
                if (property == false){
                    DispatchQueue.global( qos: DispatchQoS.QoSClass.userInteractive).async {
                        
                        self.loadAllInstanceData()
                    }
                }
            
            })
        // Load instance data
        // FIXME Do we want to be lazy about this? Loading the 6 or 7 rows when required is probably a heck of a lot faster
        DispatchQueue.global( qos: DispatchQoS.QoSClass.userInteractive).async {

            self.loadAllInstanceData()
       }
    }
    
    /** loads all the instance data
        FIXME Do we want to be lazy about this? Loading the 6 or 7 rows when required is probably a heck of a lot faster
    */
    func loadAllInstanceData(){
        var to:Int64 = DataUtils.timestampFromDate( Date())
        var from =  to - DataUtils.MILLIS_PER_DAY
        var oldestTimeStamp = to
        
        //print (DataUtils.dateFromTimestamp(to))
        let dateFormatter : DateFormatter  = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        sqlHelper.dbQueue.inDatabase() {
            db in

        //lastTimestamp = 0
        let whereClause:String? =  "timestamp >= ? AND timestamp <= ?"
        let columns = ["instance_id", "timestamp", "anomaly_score"/*, "aggregation"*/, "metric_mask"]
            
            for i in 0...GrokApplication.getNumberOfDaysToSync(){
            
            let cursor = self.sqlHelper.query(db!, tableName: InstanceData.TABLE_NAME, columns: columns,
            whereClause: whereClause, whereArgs: [NSNumber(value: from as Int64), NSNumber(value: to as Int64)], sortBy: nil)
        
     
            if (cursor == nil){
             //   print (sqlHelper.database.lastError())
            }
            
            let instaceIdColumn = cursor?.columnIndex(forName: "instance_id")
            let timestampColumn = cursor?.columnIndex(forName: "timestamp")
            let anomalyColumn = cursor?.columnIndex(forName: "anomaly_score")
            let metricMaskColumn = cursor?.columnIndex(forName: "metric_mask")
            while (cursor?.next())!{
       
                let instanceId = cursor?.string(forColumnIndex: instaceIdColumn!)
                let timestamp = cursor?.longLongInt(forColumnIndex: timestampColumn!)
                let anomalyScore = Float((cursor?.double(forColumnIndex: anomalyColumn!))!)

           //   print ( DataUtils.dateFromTimestamp((timestamp)))
                var metricMask = MetricType()
                metricMask.rawValue = Int((cursor?.int(forColumnIndex: metricMaskColumn!))!)

                let anomalyValue = AnomalyValue( anomaly: anomalyScore, metricMask: metricMask)
                var cacheEntry = self.instanceDataCache[instanceId!]
                if ( cacheEntry == nil){
                    cacheEntry = InstanceCacheEntry()
                    self.instanceDataCache[instanceId!] = cacheEntry
                }
                
                cacheEntry!.data[timestamp!] =  anomalyValue
                
            
                if (timestamp! > self.lastTimestamp){
                    self.lastTimestamp = timestamp!
                }
                
                if (timestamp!<oldestTimeStamp){
                    oldestTimeStamp = timestamp!
                }
            }
            // Get previous day
            from -= DataUtils.SECONDS_IN_DAY*1000
            to -= DataUtils.SECONDS_IN_DAY*1000
        }
        }
  
        self.firstTimestamp = oldestTimeStamp
        print (DataUtils.dateFromTimestamp(self.firstTimestamp))
        print (DataUtils.dateFromTimestamp(self.lastTimestamp))

        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: TaurusDatabase.INSTANCEDATALOADED), object: self)
    }
    
    /** get Ticker symbol for the given instance ID
        - paramter intanceId: id to find symbol of
        - returns: ticker symbol, nil if the instanceId couldn't be found
    */
    func getTickerSymbol( _ instanceId: String)->String?{
        var metrics = getMetricsByInstanceId(instanceId)
        var symbol: String? = nil
        if (metrics?.isEmpty == false ) {
            // FIXME: TAUR-817: Create taurus specific instance table
            symbol = metrics?[0].getUserInfo("symbol");
        }
        return symbol;
    }

    /** update instance data
        -parameter data: instance date to update
        -result: true if update suceeded
    */
    func updateInstanceData(_ data:InstanceData)->Bool{
        if (updateInstanceDataCache(data)) {
            // Update database
            return super.updateInstanceData(data);
        }
        return false
    }
    
    
    /** Add a batch of data
        -parameter batcj: array of data to add
        -result: true if update suceeded

    */
    func addInstanceDataBatch (_ batch :[InstanceData])->Bool{
        var modified = false;
        for  data : InstanceData in batch {
            if (updateInstanceDataCache(data)) {
                modified = true;
            }
        }
        if (modified) {
            // Update database only if data was modified
            return super.addInstanceDataBatch(batch);
        }
        return false
    }
    
    
    /** delete instance
        -parameter instanceId: instance to delete
    */
    func deleteInstance(_ instanceId: String){
        instanceDataCache.removeValue(forKey: instanceId)
        lastUpdated = Int64(Date().timeIntervalSince1970*1000.0)
        super.deleteInstance(instanceId)
    }
    
    
    /** delete all data
    */
    override func deleteAll(){
        instanceDataCache = [:]
        lastUpdated = Int64(Date().timeIntervalSince1970*1000.0)
        super.deleteAll()

    }
    
    /** update instance cacha
    */
    func updateInstanceDataCache(_ data: InstanceData )->Bool {
        let taurusInstanceData = data as! TaurusInstanceData
        var cacheEntry = getInstanceCachedValues(data.getInstanceId())
        let timestamp = data.getTimestamp()
        
        if (cacheEntry != nil){
       
          
            let oldValue : AnomalyValue? = cacheEntry!.data[ timestamp]
            if (oldValue != nil){
                if ((oldValue!.anomaly == data.getAnomalyScore() ) && (oldValue!.metricMask == taurusInstanceData.getMetricMask())){
                        return false
                }
            }
            
        }
        
       // need to update
        let newValue = AnomalyValue(anomaly: data.getAnomalyScore(), metricMask: taurusInstanceData.getMetricMask())
        
        
        if ( cacheEntry == nil){
            cacheEntry = InstanceCacheEntry()
            instanceDataCache[data.getInstanceId()] = cacheEntry
        }
        
        cacheEntry!.data[timestamp] = newValue
        
        if (timestamp > lastTimestamp) {
            lastTimestamp = timestamp;
        }
        if (timestamp < firstTimestamp) {
            firstTimestamp = timestamp;
        }
        lastUpdated = DataUtils.timestampFromDate( Date())
        return true 
    }
    
    /** retrieve id from cache
        - parameter instanceId:
    */
    func  getInstanceCachedValues( _ instanceId: String) ->InstanceCacheEntry?{
        let cacheEntry = instanceDataCache[instanceId]
        return cacheEntry
    }
    
    
    /** Retrives the instance data from the cache
        - parameter instanceId : id to get data for
        - parameter from : start time
        - parameter to: end time
        - returns: dictionary of timestamps and AnomalyValue
    */
    func getInstanceData( _ instanceId : String,  from : Int64,  to : Int64) ->[Int64: AnomalyValue]?{
        var endTime = to
        if (endTime <= 0 ) {
            // Use current time as upper limit
            endTime = Int64(Date().timeIntervalSince1970*1000)
        }

        // Get instance cached values
        let cached  = getInstanceCachedValues(instanceId)
        if cached  == nil {
            return nil
        }
        
        var submap = [Int64: AnomalyValue]()
        for (key,value) in cached!.data {
            if (key >= from && key < endTime+1){
                submap[key] = value
            }
        }
        return submap
    }
}
