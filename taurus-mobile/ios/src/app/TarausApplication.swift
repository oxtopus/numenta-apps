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

/*
 class holds references to a bunch of statics factories and data
*/
class TaurusApplication : GrokApplication{
    
    static var dataFactory : TaurusDataFactory!
    static var marketCalendar : MarketCalendar = MarketCalendar()
    static var client : TaurusClient?
   
    
    static func getTaurusDatabase()->TaurusDatabase{
        return GrokApplication.database as! TaurusDatabase
    }
    
       
    static func setup(){
        dataFactory = TaurusDataFactory()
        database = TaurusDatabase( dataFactory : dataFactory)
    }
    
    static func getAggregation()->AggregationType{
        return AggregationType.Day
   }
    
    static func getTotalBarsOnChart()->Int{
        return 24
    }
   
    
    static func connectToTaurus()->TaurusClient?{
        return client
    }
    
    /** favorites are stored as a dictionary
    
    
    */
    /**
    * Checks whether the given instance was marked as a favorite by the user
    *
    * -parameter instance: The instance ID to check
    * - returns: if it is a favorite,
    */
    static func isInstanceFavorite(_ instance:String)->Bool {
    
        let favorites = UserDefaults.standard.object(forKey: "favorites")
        if (favorites == nil ){
            return false
        }
        let dict : [String:NSNumber] = favorites! as! [String : NSNumber]
        return dict[instance] != nil
    }
    
    /**
    * Return a collection with all instances marked as favorite by the user
    */
    static func getFavoriteInstances()->[String] {
        let favorites = UserDefaults.standard.object(forKey: "favorites")
        if (favorites == nil ){
            return []
        }
        let dict : [String:NSNumber] = favorites! as! [String : NSNumber]
        return Array(dict.keys)
    }
    
    /**
    * Add the given instance to the user's preference list.
 
    *
    * @- parameter instance: The instance ID to add
    */
    static func addInstanceToFavorites(_ instance: String) {
        var favorites = UserDefaults.standard.object(forKey: "favorites")
        
        if (favorites == nil){
            favorites = [String : NSNumber]()
        }
        var dict : [String: NSNumber] = favorites! as! [String : NSNumber]
        dict[instance] = 0
        UserDefaults.standard.set(dict, forKey: "favorites")
        
     }
    
    /**
    * Remove the given instance to the user's preference list.
    *     x
    * @- parameter instance: The instance ID to add
    */
    static func removeInstanceToFavorites(_ instance: String) {
        let favorites = UserDefaults.standard.object(forKey: "favorites")
        var dict : [String:NSNumber] = favorites! as! [String : NSNumber]
        dict.removeValue(forKey: instance)
        UserDefaults.standard.set(dict, forKey: "favorites")
        
    }
    
    static func getLastNotificationTime(_ instance : String)->Int64{
        
        let favorites = UserDefaults.standard.object(forKey: "favorites")
        if (favorites == nil ){
            return 0
        }
        let dict : [String:NSNumber] = favorites! as! [String : NSNumber]
        
        let data = dict[instance]
        
        if (data != nil){
            return data!.int64Value
        }
        return 0
    }
    
    static func setLastNotificationTime(_ instance : String, time: Int64){
        var favorites = UserDefaults.standard.object(forKey: "favorites")
        if (favorites == nil ){
            favorites = [String : NSNumber]()
        }
        var dict : [String:NSNumber] = favorites! as! [String : NSNumber]
        
        dict[instance] = NSNumber(value: time as Int64)
        UserDefaults.standard.set(dict, forKey: "favorites")

    }
    
}
