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
*/
import Foundation

open class Annotation {
    
    static open let TABLE_NAME = "annotation"
    var id: String!
    var timestamp: Int64
    var created: Int64
    var device: String!
    var user: String!
    var instanceId: String!
    var message: String!
    var data: String!
    
    init(cursor: FMResultSet!) {
        self.id = cursor.string(forColumn: "annotation_id")
        self.timestamp = cursor.longLongInt(forColumn: "timestamp")
        self.created = cursor.longLongInt(forColumn: "created")
        self.device = cursor.string(forColumn: "device")
        self.user = cursor.string(forColumn: "user")
        self.instanceId = cursor.string(forColumn: "instance_id")
        self.message = cursor.string(forColumn: "message")
        self.data = cursor.string(forColumn: "data")
    }
    
    func getValues() -> Dictionary<String, AnyObject>! {
        var values = Dictionary<String, AnyObject>()
        
        values["annotation_id"] = self.id as AnyObject
        values["timestamp"] = NSNumber(value: self.timestamp as Int64)
        values["created"] = NSNumber(value: self.created as Int64)
        values["device"] = self.device as AnyObject
        values["user"] = self.user as AnyObject
        values["instance_id"] = self.instanceId as AnyObject
        values["message"] = self.message as AnyObject
        values["data"] = self.data as AnyObject
        return values
    }
    
    init(annotationId: String!, timestamp: Int64, created: Int64, device: String!, user: String!, instanceId: String!, message: String!, data: String!) {
        self.id = annotationId
        self.timestamp = timestamp
        self.created = created
        self.device = device
        self.user = user
        self.instanceId = instanceId
        self.message = message
        self.data = data
    }
    
    func getId() -> String! {
        return self.id
    }
    
    func getTimestamp() -> Int64 {
        return self.timestamp
    }
    
    func getCreated() -> Int64 {
        return self.created
    }
    
    func getDevice() -> String! {
        return self.device
    }
    
    func getMessage() -> String! {
        return self.message
    }
    
    func getData() -> String! {
        return self.data
    }
    
    func getUser() -> String! {
        return self.user
    }
    
    func getInstanceId() -> String! {
        return self.instanceId
    }

    
}
