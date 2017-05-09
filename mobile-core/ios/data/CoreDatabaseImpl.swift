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

/** Implementation of Coredatabase protocol
*/
class  CoreDatabaseImpl : CoreDatabase {
    
    let DATABASE_VERSION = 1

    var dataFactory : CoreDataFactory
    var sqlHelper : SQLiteHelper
    
    var lastTimestamp : Int64 = 0
    
    /** getter for DB version
   */
    func getVersion() -> Int{
        return DATABASE_VERSION;
    }
    
    /** getter for filename
   */
    func getFileName() -> String!{
         return "grok.db"
    }
   
    /** exposed database object */
    func getReadableDatabase() -> FMDatabase!{
        return nil
    }
    
    /** exposes DB object */
    func getWritableDatabase() -> FMDatabase!{
        return nil
    }
    
    /** data factory getter
        - returns: datafactory used to created objects
    */
    func getDataFactory() -> CoreDataFactory!{
        return dataFactory;
    }
    
    /**
        - return: the last time in the database
    */
    func getLastTimestamp() -> Int64{
        return lastTimestamp
    }
    
    /** removes old records. Currently not implemented
        - returns: number of records removed
    */
    func deleteOldRecords() -> Int32{
        return -1;
    }
    
    /** removes all data from tables
    */
    func deleteAll(){
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            
            self.sqlHelper.delete(db!, table: Annotation.TABLE_NAME, whereClause : nil, whereArgs : nil)
            self.sqlHelper.delete(db!, table: Notification.TABLE_NAME, whereClause : nil, whereArgs : nil)
            self.sqlHelper.delete(db!, table:  MetricData.TABLE_NAME, whereClause : nil, whereArgs : nil)
            self.sqlHelper.delete(db!, table:  Metric.TABLE_NAME, whereClause : nil, whereArgs : nil)
            self.invalidateMetricCache()
        }
    }
    
    /** added the metric to the DB
        - parameter : metric metric to add
        - return: row id
    */
    func addMetric(_ metric: Metric!) -> Int64{
        var rowId : Int64 = -1
        
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            
            rowId = self.sqlHelper.insertWithOnConflict(db!, table: Metric.TABLE_NAME, values: metric.getValues(), conflictAlgorithm : SQLiteHelper.REPLACE)
            if (rowId != -1){
                self.updateMetricCache(metric)
            }
        }
        
        return rowId
    }
    
    /** returns all the metrics in the cache
        - returns : array of metrics
    */
    func getAllMetrics() -> [Metric]!{
        let unmutableCollection = Array(metricsCache.values)
        return unmutableCollection
    }
    
    /** get metric from cache
        - parameter : id of metric
        - returns: metric
    */
    func getMetric(_ id: String!) -> Metric!{
        return metricsCache[id]
    }
    
    /** update the metric
        - parameter: metric to add
        - returns: true if successful
    */
    func updateMetric(_ metric: Metric!) -> Bool{
  
        var rows : Int64 = 0
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in

            rows  = self.sqlHelper.update(db!, table: Metric.TABLE_NAME, values: metric.getValues(), whereClause : "metric_id = ?", whereArgs : [metric.getId()])
            
            if (rows > 0){
                self.updateMetricCache(metric)
            }
        }
        return rows>0
    }
    
    /** remove metric
        - parameter id: id of metric
        - returns: number of rows delete
    */
    func deleteMetric(_ id: String!) -> Int32{
        var rowsDeleted: Int32 = 0
        
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            rowsDeleted = self.sqlHelper.delete(db!, table: Metric.TABLE_NAME , whereClause: "metric_id = ?", whereArgs:[id])
            if (rowsDeleted>0){
                self.removeMetricFromCache(id)
            }
        }
        return rowsDeleted
    }
    
    /** get the metrics for the given instance id
     - parameter instanceId: id to find the metrics for
     - returns: array of metrics
    */
    func getMetricsByInstanceId(_ instanceId: String!) -> [Metric]!{
        var results = [Metric]()
        let values = metricsCache.values
        for metric in values {
            if (metric.getInstanceId() == instanceId){
                results.append(metric)
            }
        }
        return results;
    }
    
    /** add a collection of metric data
        - parameter batch : items to add
        - returns: true if successful
    */
    func addMetricDataBatch(_ batch: [MetricData]!) -> Bool{
        if (batch.isEmpty ){
            return false
        }
        
        let values = batch[0].getValues()
        let columns = [String](values!.keys)
        let updateStatement = ("UPDATE metric SET last_timestamp = ? "  + "WHERE metric_id = ? AND last_timestamp < ?")
        let insertStatement = sqlHelper.prepareInsertStatement(MetricData.TABLE_NAME, columns : columns, status: "IGNORE")
        
        var rowsInserted = 0
     
        sqlHelper.dbQueue.inTransaction() {
            
            db, rollback in
            
            for metricData in batch {
                if (db?.executeUpdate(insertStatement, withParameterDictionary: metricData.getValues()))! {
                    rowsInserted += 1
                    //sqlHelper.buildInsertStatement (MetricData.TABLE_NAME, data: metricData.getValues())
                    let metric = self.getMetric (metricData.getMetricId())
                    let timestamp = metricData.getTimestamp()
                    if (timestamp > (metric?.getLastTimestamp())!){
                        if (db?.executeUpdate(updateStatement, withArgumentsIn: [String(timestamp), metric?.getId()!, String(timestamp)]) )!{
                            metric?.setLastTimestamp( timestamp)
                            self.updateMetricCache(metric!)
                        }
                    }
                }
            }
        }
   
        return rowsInserted>0
    }

    /** fetch metric data for a date range and anomaly score
        - parameter metricId : name of metric
        - parameter columns: columns to fetch
        - parameter from: start time
        - parameter  to: end time
        - parameter anomalyCore : min anomaly score. 0 for all
        - parameter limit: number of items to return. 0 for all
        - returns: result set
    */
    func getMetricData(_ metricId: String!, columns: [String]!, from: Date!, to: Date!, anomalyScore: Float, limit: Int32) -> FMResultSet!{

        var selection = String()
        //var selectionArgs = [String]()
        var append = false
        if (from != nil) {
            selection += "timestamp >= " + sqlHelper.formatDate(from)
            append = true;
        }
        
        if (to != nil) {
            if (append) {
                selection+=" AND "
            }
            selection+="timestamp <= " + sqlHelper.formatDate(to)
            append = true
        }
        
        if (anomalyScore > 0) {
            if (append) {
                selection += " AND ";
            }
            selection += "anomaly_score >= " + String(anomalyScore);
            append = true;
        }
        
        if (metricId != nil) {
            if (append) {
                selection += " AND "
            }
            selection += "metric_id = '" + metricId + "'";
        }

        var limitStr:String? = nil
        if limit>0 {
            limitStr = String (limit)
        }

        var cursor : FMResultSet? = nil
        sqlHelper.dbQueue.inDatabase() {
            db in
           
            cursor  = self.sqlHelper.queryDistinct(db!, table: MetricData.TABLE_NAME, columns: columns, whereClause: selection, limit: limitStr)
        }
  
        return cursor!
    }
    
    /** add instance data to database
        - parameter batch: instance data to add
        - returns: true for success
    */
    func addInstanceDataBatch(_ batch: [InstanceData]!) -> Bool{
        if (batch == nil || batch.isEmpty) {
            return false;
        }
 
        let values = batch[0].getValues()
        let columns = [String](values!.keys)
        var rowsInserted = 0
        let insertStatement = sqlHelper.prepareInsertStatement(InstanceData.TABLE_NAME, columns : columns, status: "REPLACE")

        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            
            for instanceData in batch {
                if (db?.executeUpdate(insertStatement, withParameterDictionary: instanceData.getValues()))! {
                    rowsInserted += 1
                }
            }
        }
        return rowsInserted > 0
    }
    
    /** get instance data for time range
        - parameter instanceId: instance id of data
        - parameter columns: columns of data
        - parameter aggregation: 
        - parameter from: stat time
        - paramater to: end time
        - parameter anomalyScore : min score to fetch. 0 for all
        - parameter limit: items to fetch. 0 for all
        - returns: result set
    */
    func getInstanceData( _ instanceId: String!, columns: [String]!, aggregation: AggregationType!, from: Date!, to: Date!, anomalyScore: Float, limit: Int32) -> FMResultSet!{
        var selection = String()
        var append = false
        if (from != nil) {
            selection+="timestamp >= " + sqlHelper.formatDate(from)
            
            append = true;
        }
        
        if (to != nil) {
            if (append) {
                selection+=" AND "
            }
            selection+="timestamp <= " + sqlHelper.formatDate(to)
           
            append = true
        }
        
        if (aggregation != nil) {
            if (append) {
                selection+=" AND "
            }
            selection+="aggregation = " + String(aggregation.minutes())
            append = true        }
        
        if (anomalyScore > 0) {
            if (append) {
                selection+=" AND "
            }
            selection += "anomaly_score >= "
                selection += String(anomalyScore)
            append = true
        }
        
        
        if (instanceId != nil ) {
            if (append) {
                selection+=" AND "
            }
            selection += "instance_id = '" + instanceId + "'"
            append = true
        }
        
        var limitStr:String? = nil
        if  limit>0 {
            limitStr = String (limit)
        }

        var cursor : FMResultSet? = nil
        sqlHelper.dbQueue.inDatabase() {
            db in
            
            cursor  = self.sqlHelper.queryDistinct(db!, table: InstanceData.TABLE_NAME, columns: columns, whereClause: selection,  limit: limitStr)
        }
        
        return cursor!
    }
    
    /** Get all instances from Metric. Note this routine will load the cache which might be slow
        - returns: set of incance ids
    */
    func getAllInstances() -> Set<String>!{
        if (instanceToName.isEmpty) {
            loadMetricCache()
        }
        
        var instances = Set<String>()
        let results =  instanceToName.keys
        
        for key in results{
            instances.insert (key)
        }
       return instances
    }
    
    /** update the Instance data
        - parameter : instance to update
        - returns:  true for success
    */
    func updateInstanceData(_ _instanceData: InstanceData!) -> Bool{
       var success = false
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            
           let rows = self.sqlHelper.update(db!, table: InstanceData.TABLE_NAME, values: _instanceData.getValues(), whereClause: "aggregation = ? AND instance_id = ? AND timestamp = ?",
                whereArgs: [String(_instanceData.getAggregation()), _instanceData.getInstanceId(), String(_instanceData.getTimestamp())])
            
            success = rows>0
        }
        return success
    }
    
    
    /** Remove instance from DB
        - parameter instance : id of instance to remove
    */
    func deleteInstance(_ instance: String!){
        deleteInstanceData(instance)
        instanceToName.removeValue(forKey: instance)
        // Remove annotations associated to this instance
        deleteAnnotationByInstanceId(instance)
        
        var metrics = getMetricsByInstanceId(instance)
        // Remove metrics associated to this instance
        metrics = getMetricsByInstanceId(instance);
        for  metric in metrics! {
            deleteMetric(metric.getId())
        }
    }
    
    /** remove data for instance id
        -parameter instanceId : id of instance to remove
    */
    func deleteInstanceData(_ instanceId: String!){

        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            
            self.sqlHelper.delete( db!, table: InstanceData.TABLE_NAME , whereClause: "instance_id = ?", whereArgs:[instanceId])
        }
    }
    
    /** Returns server name for instance id. Note will load  if needed
        - parameter instanceId:  id of instance
        - returns:   String: server name
    */
    func getServerName(_ instanceId: String!) -> String!{
        if (instanceToName.isEmpty) {
            loadMetricCache()
        }

        let name = instanceToName[instanceId]
        
        if  name != nil
        {
            if name!.isEmpty == false {
                return name
            }
        }
        return instanceId
    }
    
    /** Save notification in database
        - parameter notificationId : id of notification
        - parameter metridId:    metric id
        - parameter timestampe : time stamp
        - parameter decription:
        - returns: id of added notification
    */
    func addNotification(_ notificationId: String!, metricId: String!, timestamp: Int64, description: String!) -> Int64{
        var rowId :Int64 = -1
        let notification = Notification(notificationId: notificationId, metricId: metricId, timestamp: timestamp, read: false, description: description)
        
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            
            rowId = self.sqlHelper.insertWithOnConflict(db!, table: Notification.TABLE_NAME, values: notification.getValues(), conflictAlgorithm : SQLiteHelper.REPLACE)
        }
        return rowId
    }
    
    /** Get an array of all notifications
        - returns: array of notifications
    */
    func getAllNotifications() -> [Notification]!{
        var  results = [Notification]();
        sqlHelper.dbQueue.inDatabase() {
            db in
    
            let cursor = self.sqlHelper.queryAll(db!, tableName: Notification.TABLE_NAME)
        
            while (cursor?.next())! {
                results.append(self.dataFactory.createNotification(cursor))
            }
        
            cursor?.close()
        }
        
        if results.isEmpty{
            return nil
        }
        return results
    }
    
    /** retrieve notifcation by local id
        - parameter localId : id of notication
        - returns: notification. nil for no notification
    */
    func getNotificationByLocalId(_ localId: Int32) -> Notification!{
        var result: Notification! = nil;
        sqlHelper.dbQueue.inDatabase() {
            db in

            let cursor = self.sqlHelper.query(db!, tableName: Metric.TABLE_NAME , columns: nil, whereClause:"_id = ?", whereArgs:[String(localId) as AnyObject], sortBy: nil)

            if (cursor?.next())! {
                result =  Notification(cursor: cursor)
            }
            
            cursor?.close()
        }
        return result
    }
    
    /** get count of unread notifications
        - returns: number of unread notifications
    */
    func getUnreadNotificationCount() -> Int32{
        var count : Int32 = 0
        sqlHelper.dbQueue.inDatabase() {
            db in
            count = self.sqlHelper.queryNumEntries(db!, tableName: Notification.TABLE_NAME, whereClause: "read = 0")
        }
        return count
    }
    
    
    /** get number of notifications
        - returns: number of notifications
    */
    func getNotificationCount() -> Int32{
        var count: Int32 = 0
        sqlHelper.dbQueue.inDatabase() {
            db in
            
            count = self.sqlHelper.queryNumEntries(db!, tableName: Notification.TABLE_NAME, whereClause: nil)
        }
        
        return count
    }
    
    /** mark the specified notification as read
        - parameter notificaiotnId : id of notification
        - results : true if marked read
    */
    func markNotificationRead(_ notificationId: Int32) -> Bool{
    
        var values = Dictionary<String, Any>()
        values["read"] = 1
        var rows: Int64 = 0
        sqlHelper.dbQueue.inTransaction() {
            
            db, rollback in
             let notificationIdStr = String (notificationId )
             rows  = self.sqlHelper.update( db!, table: Notification.TABLE_NAME, values: values, whereClause : "_id = ?", whereArgs : [notificationIdStr])
            }

        return rows>0
    }
    
    
    /** delete the specified notification
    - parameter localId : id of notification
    - results : rows deleted
    */
    func deleteNotification(_ localId: Int32) -> Int32{
        var deleted : Int32 = 0
        sqlHelper.dbQueue.inTransaction() {
            
            db, rollback in

            deleted = self.sqlHelper.delete(db!, table: Notification.TABLE_NAME , whereClause: "_id = ?", whereArgs:[String(localId)])
        }
       
        return deleted;
    }
    
    
    /** delete all notifications
    - results : rows deleted
    */
    func deleteAllNotifications() -> Int32{
        var deleted: Int32 = 0
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
             deleted = self.sqlHelper.delete( db!, table: Notification.TABLE_NAME , whereClause: "1", whereArgs:nil)
        }
      
        return deleted;
    }
    
    
    /** Add annotation to DB
        - parameter annotation: annotation to add
        - returns: id of added annotation
    */
    func addAnnotation(_ annotation: Annotation!) -> Int64{
        if instanceToName[annotation.getId()]==nil{
            //"Failed to add annotation to database. Missing or unknown instance id"
            return -1;
        }
        var rowId :Int64 = -1
        sqlHelper.dbQueue.inTransaction() {
            
            db, rollback in
            
            rowId = self.sqlHelper.insertWithOnConflict(db!, table: Annotation.TABLE_NAME,  values: annotation.getValues(), conflictAlgorithm : SQLiteHelper.REPLACE)
        }
       
        return rowId
    }
    
    /** get array of all annotations
        - returns: array of annotations
    */
    func getAllAnnotations() -> [Annotation]!{
        var  results = [Annotation]()
        sqlHelper.dbQueue.inDatabase() {
            db in

            let cursor = self.sqlHelper.queryAll(db!, tableName: Annotation.TABLE_NAME)
        
            while (cursor?.next())! {
                results.append(self.dataFactory.createAnnotation(cursor))
            }
        
            cursor?.close()
        }
        
        if results.isEmpty{
            return nil
        }
        return results
    }
    
    /** retrun annotation for given id
        - parameter id: id of annotation
        - returns: annotation
    */
    func getAnnotation(_ id: String!) -> Annotation!{
        
        var result :Annotation! = nil
        sqlHelper.dbQueue.inDatabase() {
            db in
            let cursor = self.sqlHelper.query( db!, tableName: Annotation.TABLE_NAME , columns: nil, whereClause:"annotation_id = ?", whereArgs:[String(describing:id) as AnyObject], sortBy: nil)
   
            if (cursor?.next())! {
             result =  Annotation(cursor: cursor)
            }
            cursor?.close()
        }
        
        return result
    }
    
    
    /** fetch the annotations
        - parameter server: 
        - parameter from: start date
        - parameter to: end date
        - returns: arrays of annotations
    */
    func getAnnotations(_ server: String!, from: Date!, to: Date!) -> [Annotation]!{
        var selection = String()
        var selectionArgs = [String]()
        var append = false
        if (from != nil) {
            selection+="timestamp >= ?";
            selectionArgs.append(sqlHelper.formatDate(from))
            append = true;
        }
        
        if (to != nil) {
            if (append) {
                selection+=" AND "
            }
            selection+="timestamp <= ?"
            selectionArgs.append(sqlHelper.formatDate(to))
            append = true
        }
        
        if (server != nil) {
            if (append) {
                selection+=" AND ";
            }
            selection+="instance_id = ?"
            selectionArgs.append(server)
        }
        
        var results = [Annotation]()
        
        sqlHelper.dbQueue.inDatabase() {
            db in
            let cursor  = self.sqlHelper.query(db!, tableName: Annotation.TABLE_NAME, columns: nil,  whereClause: selection, whereArgs: selectionArgs as [AnyObject], sortBy: "timestamp ASC, created ASC")
        
            while (cursor?.next())! {
                results.append(self.dataFactory.createAnnotation(cursor))
            }
            cursor?.close()
        }
        return results;
    }
    
    
    /** remove annotation by annotation id
    - parameter id: annotation Id
    - returns: rows deleted
    */
    func deleteAnnotation(_ id: String!) -> Int32{
         var rowsDeleted: Int32 = 0
        
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in
            
            rowsDeleted = self.sqlHelper.delete( db!, table: Annotation.TABLE_NAME , whereClause: "annotation_id = ?", whereArgs:[id])
        }
        return rowsDeleted

    }
    
    /** remove annotation by instance id
        - parameter instanceId: instance Id
        - returns: rows deleted
    */
    func deleteAnnotationByInstanceId(_ instanceId: String!) -> Int32{
        var rowsDeleted: Int32 = 0
        
        sqlHelper.dbQueue.inTransaction() {
            db, rollback in

            rowsDeleted = self.sqlHelper.delete(db!, table: Annotation.TABLE_NAME , whereClause: "instance_id = ?", whereArgs:[instanceId])
        }

        return rowsDeleted
    }


    // Internal funcs
    
    fileprivate var metricsCache = [String : Metric]()
    fileprivate var instanceToName = [String : String]()
    
    /** removes all items from the cache
    */
    fileprivate func invalidateMetricCache(){
        instanceToName.removeAll()
        metricsCache.removeAll()
    }
    
    /** updates the cache for the metric
        - parameter metric: metric to add to cache
    */
    fileprivate func updateMetricCache( _ metric : Metric ){
        metricsCache[metric.getId()] = metric;
        instanceToName[metric.getInstanceId()] = metric.getServerName()
    }
    
    /** remove metric from a the cache
      - parameter id: id of metric to remove
      - returns: metric that was removed
    */
    fileprivate func removeMetricFromCache (_ id: String)->Metric?{
        if let metric =  metricsCache.removeValue(forKey: id){
            instanceToName.removeValue( forKey: metric.getInstanceId())
             deleteAnnotationByInstanceId(metric.getInstanceId())
            return metric
        }
    	
        return nil
    }
    
    
    /** load the metric cache
    */
    fileprivate func loadMetricCache(){
        invalidateMetricCache()
        
       
        sqlHelper.dbQueue.inDatabase() {
            db in
            
            let cursor = self.sqlHelper.queryDistinct(db!, table:Metric.TABLE_NAME, columns: nil, whereClause: nil, limit: nil)
        
        
            if (cursor == nil){
                return
            }
            while (cursor?.next())!{
                let metric = self.dataFactory.createMetric(cursor)
                self.instanceToName[(metric?.getInstanceId())!] =  metric?.getServerName()
                self.metricsCache[(metric?.getId())!] = metric
                
            }
        }
    }
    
    /**
    - parameter dataFactory : factory to create objects
    */
    init(dataFactory : CoreDataFactory ){
        sqlHelper = SQLiteHelper(name: "grok.db")
      //  database = sqlHelper.database;
        self.dataFactory  = dataFactory
    }

}
