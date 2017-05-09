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

open class Notification {
  
    static let TABLE_NAME: String! = "notification"
    var id: Int32
    var notificationId: String!
    var metricId: String!
    var timestamp: Int64
    var read: Bool
    var description: String!

    init(cursor: FMResultSet!) {
        self.id = cursor.int(forColumn: "_id")
        self.notificationId = cursor.string(forColumn: "notification_id")
        self.metricId = cursor.string(forColumn: "metric_id")
        self.timestamp = cursor.longLongInt(forColumn: "timestamp")
        self.read = cursor.int(forColumn: "read") == 1
        self.description = cursor.string(forColumn: "description")
    }

    init(notificationId: String!, metricId: String!, timestamp: Int64, read: Bool, description: String!) {
        self.notificationId = notificationId
        self.metricId = metricId
        self.timestamp = timestamp
        self.read = read
        self.description = description
        self.id = -1;
    }

    func getValues() -> Dictionary<String, AnyObject>! {
        var values = Dictionary<String, AnyObject>()
       
        values["_id"] = NSNumber(value: self.id as Int32)
        values["notification_id"] = self.notificationId as AnyObject
        values["metric_id"] = self.metricId as AnyObject
            values["timestamp"] = NSNumber(value: self.timestamp as Int64)
            values["read"] = NSNumber(value: self.read as Bool)
        values["description"] = self.description as AnyObject
        return values
    }

 /*   func getLocalId() -> Int32 {
        return id
    }

    func getNotificationId() -> String! {
        return notificationId
    }

    func getMetricId() -> String! {
        return metricId
    }

    func getTimestamp() -> Int64 {
        return timestamp
    }

    func getDescription() -> String! {
        return description
    }

    func isRead() -> Bool {
        return self.read
    }

    func setDescription(description: String!) {
        self.description = description
    }
  */
}
