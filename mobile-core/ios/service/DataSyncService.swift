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


open class DataSyncService{
    var client : GrokClient

    /*Bunch of strings used for notifications of data changed events */
    
    static let  METRIC_DATA_CHANGED_EVENT = "com.numenta.core.data.MetricDataChangedEvent"
    /**
    * This Event is fired on metric changes
    */
    open static let METRIC_CHANGED_EVENT = "com.numenta.core.data.MetricChangedEvent"
    
    /**
    * This Event is fired on annotations changes
    */
    open static let ANNOTATION_CHANGED_EVENT = "com.numenta.core.data.AnnotationChangedEvent"
    
    /**
    * This Event is fired when the server starts and stops downloading data. Check event's <b>
    * <code>isRefreshing</code></b> parameter for refreshing status.
    */
    open static let REFRESH_STATE_EVENT = "com.numenta.core.data.RefreshStateEvent"

    
    /**
     * This Event is fired when the server starts and stops downloading data. Check event's <b>
     * <code>isRefreshing</code></b> parameter for refreshing status.
     */
    open static let PROGRESS_STATE_EVENT = "com.numenta.core.data.ProgressStateEvent"
    
    /**
    * Default Refresh rate in minutes. User may override using application settings
    */
    open static let REFRESH_RATE = "5"
  
    
    /** Broadcast the REFRESH_STATE_EVENT notification
    */
    func fireRefreshStateEvent(_ isRefreshing: Bool, result: String){
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: DataSyncService.REFRESH_STATE_EVENT), object: isRefreshing)
    }
    
    
    /** Broadcast the METRIC_CHANGED_EVENT notification
    */
    func fireMetricChanged(){
         NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: DataSyncService.METRIC_CHANGED_EVENT), object: self)
    }
    
    /** Broadcast the METRIC_DATA_CHANGED_EVENT notification
    */
    func fireMetricDataChanged(){
         NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: DataSyncService.METRIC_DATA_CHANGED_EVENT), object: self)
    }
    
    /** Broadcast the ANNOTATION_CHANGED_EVENT notification
    */
    func fireAnnotationChanged(){
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: DataSyncService.ANNOTATION_CHANGED_EVENT), object: self)
    }
    
    /** Syncs metrics with DB
        - returns: number of metrics added
    */
    func loadAllMetrics()->Int32 {
        
        var metricsAdded :Int32 = 0
        // Get metrics from server
        let remoteMetrics = client.getMetrics();
        if (remoteMetrics?.count == 0 ) {
            return 0;
        }
      
        var metricSet = Set<String>()
        // Save results to database
        var dataChanged = false;
       // Metric localMetric;
        let database = GrokApplication.getDatabase()
        for  remoteMetric in remoteMetrics! {
            // Check if it is a new metric
            let localMetric = database.getMetric(remoteMetric?.getId());
            if (localMetric == nil) {
                database.addMetric(remoteMetric);
                dataChanged = true;
                metricsAdded += 1
            } else {
                // Check for metric changes
                if (remoteMetric?.getLastRowId() != localMetric?.getLastRowId()) {
                    // Use local metric last timestamp
                    remoteMetric?.setLastTimestamp((localMetric?.getLastTimestamp())!);
                    // Update metric.
                    database.updateMetric(remoteMetric);
                }
            }
            metricSet.insert((remoteMetric?.getId())!);
        }
        
        // Consolidate database by removing metrics from local cache
        // that were removed from the server
  
            for metric in database.getAllMetrics() {
                if (!metricSet.contains(metric.getId())) {
                    database.deleteMetric(metric.getId())
                    dataChanged = true;
                }
            }

        if (dataChanged) {
            fireMetricChanged()
        }
        return metricsAdded
    }
    
    //
    func scheduleUpdate (_ rate : Int64){
      // fix me need to implement
    }
    
    /** Sync the server and database. Runs the sync on a background thread
        - FIXME need to change this to use iOS background service
    */
    func synchronizeWithServer () {
                self.fireRefreshStateEvent(true, result: "")
                self.loadAllMetrics()
                self.loadAllAnnotations()
                self.loadAllData()
                self.synchronizeNotification()
                self.fireRefreshStateEvent (false, result: "")
        
    }
    
    func synchronizeNotification (){
        // not used
    }
    
    func loadAllData(){
        // not used for  Taurus
    }
    
    func loadAllAnnotations() {
         // not used for
    }
    
    func deleteAnnotation( _ annotationId: String) {
        // not used
    }
    
    func addAnnotation ( _ timestamp: Date, server :String , message: String, user : String ){
        // not used
    }
    
    func forceRefresh(){
        
    }
    
    
    /** Construct sync service
        - parameter client: GrokClient to use for syncing
    */
    init(client : GrokClient) {
        self.client = client
    }
    
    
    
    
    
}
