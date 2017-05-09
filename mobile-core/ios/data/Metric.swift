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


/**
* Helper class representing one "metric" record
*/
open class Metric {
 //   let serialVersionUID: Int64 = 5441566818295535142
    //  /** Database Table name */
    static let TABLE_NAME: String! = "metric"
    var metricId: String!
    var name: String!
    var instanceId: String!
    var lastRowId: Int32
    var serverName: String!
    var parameters: String!
    //  /** Holds parsed parameters */
    var parametersJson: JSON!
    var lastTimestamp: Int64

    init(_ cursor: FMResultSet!) {
       self.metricId = cursor.string(forColumn: "metric_id")
        self.lastRowId = cursor.int(forColumn: "last_rowid")
        self.name = cursor.string(forColumn: "name")
        self.instanceId = cursor.string(forColumn: "instance_id")
        self.serverName = cursor.string(forColumn: "server_name")
        self.lastTimestamp = cursor.longLongInt(forColumn: "last_timestamp")
        //  // Get metric JSON Parameters from the database
        self.parameters = cursor.string(forColumn: "parameters")
        
        if (self.parameters != nil){
            let dataFromString = self.parameters.data(using: String.Encoding.utf8, allowLossyConversion: false)
            do {
                self.parametersJson = try JSON( data: dataFromString!)
            } catch { print(error)}
        }
    }

    init(metricId: String!, name: String!, instanceId: String!, serverName: String!, lastRowId: Int32, parameters: JSON!) {
        self.metricId = metricId
        self.name = name
        self.instanceId = instanceId
        self.serverName = serverName
        self.lastRowId = lastRowId
        self.parametersJson = parameters
        self.parameters = parameters != nil ? parameters.rawString() : nil
        // Should be updated with the the last timestamp available in the
        // metric_data table
        self.lastTimestamp = 0
    }

    func getValues() -> Dictionary<String, AnyObject>! {
        var values = Dictionary<String, AnyObject>()
        values["metric_id"] = self.metricId as AnyObject
        values["last_rowid"] = NSNumber(value: self.lastRowId as Int32)
        values["name"] = self.name as AnyObject
        values["instance_id"] = self.instanceId as AnyObject
        values["server_name"] = self.serverName as AnyObject
        values["last_timestamp"] = NSNumber(value: self.lastTimestamp as Int64)
        if self.parameters != nil {
            values["parameters"] = self.parameters as AnyObject
        }
        return values
    }

    func getParameter(_ name: String!) -> String! {
        if parametersJson != nil {
            return parametersJson[name].stringValue
        }
        return nil
    }

    func getMetricSpec(_ name: String!) -> String! {
        if parametersJson != nil {
            let spec: JSON! = parametersJson["metricSpec"]
            if spec != nil {
                return spec[name].stringValue
            }
        }
        return nil
    }

    func getUserInfo(_ name: String!) -> String! {
        if parametersJson != nil {
            
            let spec: JSON! = parametersJson["metricSpec"]
 
            if spec != nil {
                let info:JSON!  = spec["userInfo"]
                if info != nil {
                    return info[name].stringValue
                }
            }
        }
        return nil
    }

    func getId() -> String! {
        return self.metricId
    }

    func getName() -> String! {
        return self.name
    }

    func getServerName() -> String! {
        return self.serverName
    }

    func getInstanceId() -> String! {
        return self.instanceId
    }

    func getLastRowId() -> Int32 {
        return lastRowId
    }

    func getUnit() -> String! {
        var unit: String! = getParameter("unit")
        if unit == nil {
            unit = getMetricSpec("unit")
        }
        return unit
    }



    func getLastTimestamp() -> Int64 {
        return self.lastTimestamp
    }

    func setLastTimestamp(_ lastTimestamp: Int64) {
        self.lastTimestamp = lastTimestamp
    }

 
}
