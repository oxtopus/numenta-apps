/* 
* Numenta Platform for Intelligent Computing (NuPIC)
* Copyright (C) 2015, Numenta, Inc. Unless you have purchased from
* Numenta, Inc. a separate commercial license for this software code, the
* following terms and conditions apply:
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero Public License version 3 as
* published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
* See the GNU Affero Public License for more details.
*
* You should have received a copy of the GNU Affero Public License
* along with this program. If not, see http://www.gnu.org/licenses.
*
* http://numenta.org/licenses/
*
*/

import Foundation
import UIKit

class TaurusNotificationService{
    
    func syncNotifications(){
        
        // check if notifications are enabled let defaults = NSUserDefaults.standardUserDefaults()
        let frequency : Int64 =  Int64 (UserDefaults.standard.integer(forKey: "maxNotificationsPerCompany")) * 1000
        
        let now = Date()
        let lastRunTime =  UserDefaults.standard.object(forKey: "LastNotification")
        let flooredDate = DataUtils.dateFromTimestamp(DataUtils.floorTo60Minutes( DataUtils.timestampFromDate(now)))
         UserDefaults.standard.set(flooredDate, forKey: "LastNotification")
        
        let lastTimestamp = lastRunTime == nil ? 0 : DataUtils.timestampFromDate(lastRunTime as! Date)
        let notifications = getNotifications(lastTimestamp, end: DataUtils.timestampFromDate(now), frequency: frequency)
    
        if ( notifications.count == 0){
            return
        }
        // Build OS notifications
    
        var alertBody = ""
        for notification in  notifications {
            TaurusApplication.setLastNotificationTime(notification.getInstanceId(), time: notification.timestamp)
            if (alertBody.isEmpty == false){
                alertBody += "\n"
                
            }
            alertBody += notification.description
        }
        
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 5)
        notification.alertBody = alertBody
       // notification.alertAction = "be awesome!"
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.shared.scheduleLocalNotification(notification)
        
        

        
    }
    
    
    func getNotifications( _ start : Int64, end :Int64, frequency : Int64)->[TaurusNotification]{
        let favorites = TaurusApplication.getFavoriteInstances()
        var results = [TaurusNotification]()
        var anomalies = [String: (Int64, AnomalyValue)]()

        for instance in favorites {
            let lastFired = TaurusApplication.getLastNotificationTime(instance)
            if (lastFired > end - frequency){
                // Already showed a notification
                continue
            }
            
           let instanceData =  TaurusApplication.getTaurusDatabase().getInstanceData (instance, from: start, to: end)
        
            for value in instanceData! {
                
                let logScale = DataUtils.logScale(Double(abs(value.1.anomaly)))
                
                if (Float(logScale) >= TaurusApplication.redBarFloor){
                    
                    if (value.1.metricMask.contains( MetricType.StockVolume) ||
                        value.1.metricMask.contains( MetricType.StockPrice)
                        ){
                           anomalies[instance] = value
                    }
                }
            }
        }
        
        // Create notifications
        for (instance, value) in anomalies {
            let timestamp = value.0
            let mask = value.1.metricMask
            let text = formatAnomalyTitle (instance, mask: mask, timestamp: timestamp)
            let notification = TaurusApplication.dataFactory.createNotification(instance, timestamp: timestamp, description: text)
            results.append(notification as! TaurusNotification)
        }
 
        return results
    }
    
    func formatAnomalyTitle (_ instance: String, mask: MetricType, timestamp : Int64)->String{
        var anomalyTypes = ""
        if ( mask.contains(MetricType.StockPrice) || mask.contains(MetricType.StockVolume) ){
            
            if ( mask.contains(MetricType.TwitterVolume)){
                anomalyTypes = "Stock & Twitter"
            }else{
               anomalyTypes = "Stock"
            }
        } else
            if ( mask.contains(MetricType.TwitterVolume)){
                anomalyTypes = "Twitter"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.short
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: DataUtils.dateFromTimestamp(timestamp))
        

        let resultStr = instance + "(" + anomalyTypes + "):" + dateString
        
        return resultStr
    }
}
