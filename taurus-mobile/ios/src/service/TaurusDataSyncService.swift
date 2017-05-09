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


open class TaurusDataSyncService: DataSyncService{
    /**
     * This Event is fired on instance data changes
     */
    open static let INSTANCE_DATA_CHANGED_EVENT = "com.numenta.taurus.data.InstanceDataChangedEvent"

    /** loads  instance data
    */
    override func loadAllData() {
    
        let db = TaurusApplication.getTaurusDatabase()
        var from = db.getLastTimestamp()
    
        let nowDate = Date()
        let now = DataUtils.timestampFromDate( nowDate )
        // The server updates the instance data table into hourly buckets as the models process
        // data. This may leave the last hour with outdated values when the server updates the
        // instance data table after we start loading the new hourly bucket.
        // To make sure the last hour bucket is updated we should get data since last update up to
        // now and on when the time is above a certain threshold (15 minutes) also download the
        // previous hour once.
        
        
        let defaults = UserDefaults.standard
        var date = defaults.object(forKey: "previous_hour_threshold") as? Date
        if ( date == nil ){
            date = Date()
        }

        if (now >= DataUtils.timestampFromDate(date!)) {
            // Download the previous hour
            from -= DataUtils.MILLIS_PER_HOUR;
            let units : NSCalendar.Unit = [NSCalendar.Unit.year,
                NSCalendar.Unit.month,
                NSCalendar.Unit.day,
                NSCalendar.Unit.hour,
                NSCalendar.Unit.minute]
            
            
           
            var newDate =  (Calendar.current as NSCalendar).date(
                byAdding: NSCalendar.Unit.hour, // adding hours
                value: 1,
                to: nowDate ,
                options: []
            )
            
            
            var components = (Calendar.current as NSCalendar).components (units, from: newDate!)
            components.minute = 15
            components.second = 0
           
            newDate = Calendar.current.date(from: components)
            
            defaults.set( newDate, forKey: "previous_hour_threshold")
        }
        
        
        
        let oldestTimestamp = DataUtils.floorTo60Minutes (  now - TaurusApplication.getNumberOfDaysToSync() * DataUtils.MILLIS_PER_DAY )
        
        // Check if we need to catch up and download old data
        if ( db.firstTimestamp - DataUtils.MILLIS_PER_HOUR > oldestTimestamp){
            from = oldestTimestamp
        }
        
        // Don't fetch data olders than NUMBER_OF_DAYS_TO_SYNC
        
        from = max (from, oldestTimestamp)
        
        let fromDate = DataUtils.dateFromTimestamp( from )
        
        var results = [InstanceData]()
        getClient().getAllInstanceData(  fromDate,  to: nowDate,  ascending : false, callback:{
            (instance: InstanceData?) in
            
            if (instance == nil ){
                if (results.count > 0) {
                    db.addInstanceDataBatch( results )
                    self.fireInstanceDataChangedEvent()
                }
                
                return nil
            }
            results.append (instance!)
            
            if (results.count > 50 ){
                db.addInstanceDataBatch( results )
                self.fireInstanceDataChangedEvent()
                results.removeAll()
            }
            
            return nil
            }
            
        )
    }
    /** Broadcast the ANNOTATION_CHANGED_EVENT notification
     */
    func fireInstanceDataChangedEvent() {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: TaurusDataSyncService.INSTANCE_DATA_CHANGED_EVENT), object: self)
    }


    override func synchronizeNotification (){
        TaurusNotificationService().syncNotifications()
    }
    

    override func loadAllMetrics() -> Int32 {
        return super.loadAllMetrics()
    }
    
    override func loadAllAnnotations() {
        // do nothing<#code#>
    }
    
    
    func getClient()->TaurusClient {
        return client as! TaurusClient;
    }
}
