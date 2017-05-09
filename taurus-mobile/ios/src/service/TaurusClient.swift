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

open class TaurusClient : GrokClient {
    
    static let TABLE_SUFFIX : String  = AppConfig.currentStage 
    
    static let  METRIC_TABLE : String = "taurus.metric" + TABLE_SUFFIX
    static let  METRIC_DATA_TABLE : String = "taurus.metric_data" + TABLE_SUFFIX
    static let  INSTANCE_DATA_HOURLY_TABLE : String = "taurus.instance_data_hourly" + TABLE_SUFFIX
    static let  TWEETS_TABLE : String = "taurus.metric_tweets" + TABLE_SUFFIX
    
    var awsClient : AWSDynamoDB

    /** Initialize client
        - parameter provider: AWS credentional provider
        - parameter region: AWRS region
    */
    init( provider : AWSCredentialsProvider, region: AWSRegionType){
        let configuration = AWSServiceConfiguration(region: AWSRegionType.usWest2, credentialsProvider: provider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        awsClient = AWSDynamoDB.default()
    }
    
    /** Check if data connection is available
        returns: true if available.
    */
    open func isOnline() -> Bool{
        // FIXME
        // Check for network connection
        return true
    }
    
    
    /** No login for taurus
    */
    open func login(){
        // Do nothing
    }
    
    
    /** no server url for taurus
    */
    open func getServerUrl() -> String!{
        return nil
    }
    
    /** returne name of server
    */
    open func getServerName() -> String! {
        return "Taurus"
    }
    
    open func getServerVersion() -> Int{
        return 0
    }
    
    /** get list of metrics from server
        - returns: array of metrics
    */
    open func getMetrics() -> [Metric?]!{
        var metrics = [Metric]()
        print("getMetrics")
        let  request: AWSDynamoDBScanInput =  AWSDynamoDBScanInput()
        request.tableName = TaurusClient.METRIC_TABLE
        request.attributesToGet = ["uid", "name", "server", "metricType","metricTypeName","symbol" ]
        
        repeat{
            
            let task = awsClient.scan(request).continue({ (task: AWSTask!) -> Any? in
                let error = task.error
                if (error != nil ){
                    print(error!)
                    return nil
                }
                let taskResult = task.result
                //  print (taskResult)
                var results = taskResult as! AWSDynamoDBScanOutput
                //print("Results: ")
                //print(results)
                
                
                //print(results.dictionaryValue[0])
                //print(results.items)
               
                for object in results.items{
                    
                    if let item = object as? [String:Any] {
                 
                        let uid = (item["uid"] as! AWSDynamoDBAttributeValue).s
                        let name = (item["name"] as! AWSDynamoDBAttributeValue).s
                        let server = (item["server"] as! AWSDynamoDBAttributeValue).s
                        let metricType =  (item["metricType"] as! AWSDynamoDBAttributeValue).s
                        let metricTypeName = (item["metricTypeName"] as! AWSDynamoDBAttributeValue).s
                        let symbol = (item["symbol"] as! AWSDynamoDBAttributeValue).s
                    
                        var pString =   "{\"metricSpec\":{\"userInfo\": {\"symbol\": \"" + symbol!
                            pString += "\",\"metricType\": \"" + metricType!
                            pString +=  "\",\"metricTypeName\": \"" + metricTypeName! + "\"}}}"
                        
                        let dataFromString = pString.data(using: String.Encoding.utf8, allowLossyConversion: false)
                        do {
                            let json = try JSON(data: dataFromString!)
                            let metric = TaurusApplication.dataFactory.createMetric( uid, name: name, instanceId: server, serverName: server, lastRowId: 0, parameters: json)
                            print("metric name: " + (metric?.getName())!)
                            metrics.append(metric!)
                        } catch {print(error)}
                    }
                }
                
                request.exclusiveStartKey =  results.lastEvaluatedKey
        
                return()
                } as AWSContinuationBlock)
        
            task?.waitUntilFinished()
        } while  request.exclusiveStartKey != nil
        return metrics
    }
    
    open func getMetricData(_ modelId: String!, from: Date!, to: Date!, callback: (MetricData!)->Bool!){
        // do nothing
    }
    
    open func getNotifications() -> [Notification?]!{
        // Do nothing
        return nil
    }
    
    open func acknowledgeNotifications(_ _ids: [String?]!){
        // do nothing, taurus notifications are managed by the client
    }
    
    open func getAnnotations(_ from: Date!, to: Date!) -> [Annotation?]!{
       // Do Nothing
        return nil
    }
    
    open func deleteAnnotation(_ _annotation: Annotation!){
        // Do nothing
    }
    
    open func addAnnotation(_ timestamp: Date!, server: String!, message: String!, user: String!) -> Annotation!{
        // Do nothing
        return nil
    }
    
    func clearCache(){
        // fix me
    }
    
    /** Retrieve tweets from server
        - parameter metricName : metric to get tweets for
        - parameter from : start time
        - paramter to: end time
        - parameter callback : will be called once for each tweet
    */
    func getTweets ( _ metricName: String, from: Date, to : Date, callback : @escaping (Tweet?)->Void? ){
        var keyConditions : [String: AWSDynamoDBCondition] = [: ]
        let dateFormatter : DateFormatter  = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        // Set up the UID condition
        let metricCondition = AWSDynamoDBCondition()
        metricCondition?.comparisonOperator = AWSDynamoDBComparisonOperator.EQ
        
        let metricAttr = AWSDynamoDBAttributeValue()
        metricAttr?.s = metricName
        
        metricCondition?.attributeValueList = [metricAttr]
        keyConditions["metric_name"] = metricCondition
        
        // Set up the date Condition
        let timestampCondition = AWSDynamoDBCondition()
        timestampCondition?.comparisonOperator = AWSDynamoDBComparisonOperator.between
        
        let fromAttr = AWSDynamoDBAttributeValue()
        fromAttr?.s = dateFormatter.string(from: from)
        
        let toAttr = AWSDynamoDBAttributeValue()
        toAttr?.s = dateFormatter.string(from: to)
        
        
        if ( from.compare(to) == ComparisonResult.orderedAscending) {
            timestampCondition?.attributeValueList = [fromAttr, toAttr]
        }else{
            
            // This should never happen
            timestampCondition?.attributeValueList = [toAttr, fromAttr]
        }
        
        keyConditions["agg_ts"] = timestampCondition
        
        
        let query = AWSDynamoDBQueryInput()
        query?.tableName = TaurusClient.TWEETS_TABLE
        

        query?.attributesToGet=["tweet_uid","userid", "text", "username",
            "agg_ts", "created_at", "retweet_count"]
        query?.keyConditions = keyConditions
        query?.scanIndexForward = false
        query?.indexName = "taurus.metric_data-metric_name_index"
        
        var done = false
        print("getTweets")
        repeat {
            let task =  awsClient.query( query).continue({ (task: AWSTask!) -> Any? in
                let error = task.error
                if (error != nil ){
                    print(error!)
                    return nil
                }
                let taskResult = task.result
                let results = taskResult as! AWSDynamoDBQueryOutput
                
                let myResults  = results.items
            
                for object in myResults!{
         
                    if let item = object as? [String:Any] {
                        //    print( item )
                        let tweetId = (item["tweet_uid"] as! AWSDynamoDBAttributeValue).s

                        let userId = (item["userid"] as! AWSDynamoDBAttributeValue).s
                        let text = (item["text"] as! AWSDynamoDBAttributeValue).s
                        let userName = (item["username"] as! AWSDynamoDBAttributeValue).s
                        let aggregated = DataUtils.parseHTMDate((item["agg_ts"]as! AWSDynamoDBAttributeValue).s)
                        let created = DataUtils.parseHTMDate((item["created_at"]as! AWSDynamoDBAttributeValue).s)
                        
                        let retweet = item["retweet_count"] as? AWSDynamoDBAttributeValue
                        var retweetCount : Int32 = 0
                        
                        if (retweet != nil && retweet!.n != nil){
                            retweetCount = Int32 (retweet!.n)!
                        }
            
                        let tweet = TaurusApplication.dataFactory.createTweet( tweetId!, aggregated: aggregated!, created: created!, userId: userId!, userName: userName!, text: text!, retweetCount: retweetCount)
                        
                        
                        callback (tweet)
                       } 
                }
                query?.exclusiveStartKey =  results.lastEvaluatedKey
                if (results.lastEvaluatedKey == nil){
                    done = true
                    
                }
                return()
                } as AWSContinuationBlock)
            task?.waitUntilFinished()
        } while !done
    }
    
    /** fetch metric values for given id between the specified date range
        - parameter modelId
        - parameter from : start date
        - parameter to: end Date
        - parameter ascending: sort order
        - parameter  callback: will be called for each metric value
    */
    func getMetricsValues (_ modelId: String, from:Date, to: Date, ascending: Bool, callback : @escaping ( _ metricId: String,  _ timestamp: Int64,  _ value: Float,  _ anomaly: Float)->Bool ) {
       
        //Do I need a Cache?
        var keyConditions : [String: AWSDynamoDBCondition] = [: ]
        let dateFormatter : DateFormatter  = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier : "UTC")

        
        // Set up the UID condition
        let uidCondition = AWSDynamoDBCondition()
        uidCondition?.comparisonOperator = AWSDynamoDBComparisonOperator.EQ
        
        let uidAttr = AWSDynamoDBAttributeValue()
        uidAttr?.s = modelId
       
        uidCondition?.attributeValueList = [uidAttr]
        keyConditions["uid"] = uidCondition
        
        // Set up the date Condition
        let timestampCondition = AWSDynamoDBCondition()
        timestampCondition?.comparisonOperator = AWSDynamoDBComparisonOperator.between
        
        let fromAttr = AWSDynamoDBAttributeValue()
        fromAttr?.s = dateFormatter.string(from: from)
        
        let toAttr = AWSDynamoDBAttributeValue()
        toAttr?.s = dateFormatter.string(from: to)
        
        
        if ( from.compare(to) == ComparisonResult.orderedAscending) {
            timestampCondition?.attributeValueList = [fromAttr, toAttr]
        }else{
            
            // This should never happen
              timestampCondition?.attributeValueList = [toAttr, fromAttr]
        }
        
        keyConditions["timestamp"] = timestampCondition

        let query = AWSDynamoDBQueryInput()
        query?.tableName = TaurusClient.METRIC_DATA_TABLE

        query?.attributesToGet=["timestamp", "metric_value", "anomaly_score"]
        query?.keyConditions = keyConditions
        query?.scanIndexForward = ascending as NSNumber
        
        print("getMetricValues")
        var done = false
        repeat {
            let task =  awsClient.query( query).continue({ (task: AWSTask!) -> Any? in
                let error = task.error
                if (error != nil ){
                    print(error!)
                    return nil
                }
                let taskResult = task.result
                //  print (taskResult)
                let results = taskResult as! AWSDynamoDBQueryOutput
                
                let myResults  = results.items
                //   print("object: \(myResults.description)")
              //  let dateFormatter = NSDateFormatter()
              //  dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH"
                
                for object in myResults!{
                    //    print( item )
                    if let item = object as? [String:Any] {
                        let timeStr = item["timestamp"] as! AWSDynamoDBAttributeValue
                        let date = DataUtils.parseGrokDate(timeStr.s)
                        let value = Float((item["metric_value"] as! AWSDynamoDBAttributeValue).n)!
                        let anonomaly_score = Float((item["anomaly_score"] as! AWSDynamoDBAttributeValue).n)!
                        print("Successfully metrics value retrieved: " + String(describing: anonomaly_score))
        
                        let dateSeconds = DataUtils.timestampFromDate(date!)
                        
                        
                       let shouldCancel =  callback  ( modelId,  dateSeconds,  value,  anonomaly_score)
                        
                        if (shouldCancel){
                            done = true
                            break
                        }
        
                    }
                }
                query?.exclusiveStartKey =  results.lastEvaluatedKey
                if (results.lastEvaluatedKey == nil){
                    done = true
                }
            return()
            } as AWSContinuationBlock)
            task?.waitUntilFinished()
        } while !done
    }
    
    
    /** get instance date for a given date range
        - parameter date : day
        - parameter  fromHour : star hour
        - parameter  toHour: end hour
        - parameter  ascending: sort order
        - parameter  callback: called for each instance data
    */
    func getAllInstanceDataForDate( _ date : Date,  fromHour: Int,  toHour : Int,
        ascending : Bool,callback : @escaping (InstanceData?)->Void?){
            let query = AWSDynamoDBQueryInput()
            query?.tableName = TaurusClient.INSTANCE_DATA_HOURLY_TABLE
            var keyConditions : [String: AWSDynamoDBCondition] = [: ]
            
            let dateFormatter : DateFormatter  = DateFormatter()
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")!
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let dateStr  = dateFormatter.string( from: date )
            let dateCondition = AWSDynamoDBCondition()
            dateCondition?.comparisonOperator = AWSDynamoDBComparisonOperator.EQ
            
            let dateAttr = AWSDynamoDBAttributeValue()
            dateAttr?.s = dateStr
            
            dateCondition?.attributeValueList = [dateAttr!]
            keyConditions["date"] = dateCondition
            
            let fromStr = String(format: "%02d", fromHour)
            let toStr = String(format: "%02d", toHour)
            
            let fromAttr = AWSDynamoDBAttributeValue()
            fromAttr?.s = fromStr
            
            
            let toAttr = AWSDynamoDBAttributeValue()
            toAttr?.s = toStr
            
            let timeCondition = AWSDynamoDBCondition()
            if (fromHour == toHour){
                timeCondition?.comparisonOperator = AWSDynamoDBComparisonOperator.EQ
                timeCondition?.attributeValueList = [fromAttr!]
            }else{
                
                timeCondition?.comparisonOperator = AWSDynamoDBComparisonOperator.between
                timeCondition?.attributeValueList = [fromAttr!, toAttr!]
            }
        
         //   keyConditions["hour"] = timeCondition

            query?.attributesToGet=["instance_id", "date_hour", "anomaly_score"]
            query?.keyConditions = keyConditions
            query?.scanIndexForward = ascending as NSNumber
            query?.indexName = "taurus.instance_data_hourly-date_hour_index"
            
        
            var done = false
        
            
            repeat {
                let task = awsClient.query( query).continue({ (task: AWSTask!) -> Any? in
                    print("No error produced so far")
                    let error = task.error
                    if (error != nil ){
                        print(error!)
                        return nil
                    }
                    let taskResult = task.result
                    let results = taskResult as! AWSDynamoDBQueryOutput
                    
                    let myResults  = results.items
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH"
                    dateFormatter.timeZone =  TimeZone(identifier : "UTC")
                    
                    //let json = JSON(data: myResults)
                    print("getting all instance data for date")
                    
                    for object in myResults!{
                        if let item = object as? [String:Any]{
                            var anomalyScore :Double = 0.0
                            let date_hour = item["date_hour"] as! AWSDynamoDBAttributeValue
                            let instance_id = (item["instance_id"] as! AWSDynamoDBAttributeValue).s
                            let anonomaly_score = (item["anomaly_score"] as! AWSDynamoDBAttributeValue).m
                            //    print (date_hour)
                            let date = dateFormatter.date( from: date_hour.s)!
                            //   print ( "instanceData" + date.description)
                            var metricMask = MetricType()
                            
                            /*    print (instance_id)
                             print (date)
                             print (anonomaly_score)
                             */
                            let dateSeconds =  DataUtils.timestampFromDate(date)
                            
                            
                            for (key, anomalyValue) in anonomaly_score! {
                                let score :Double = Double ( (anomalyValue as AnyObject).n)!
                                let scaledScore = DataUtils.logScale(abs(score))
                                //   print ("score : %s", scaledScore)
                                
                                if (Float(scaledScore) >= TaurusApplication.yellowBarFloor){
                                    metricMask.insert(MetricType.enumForKey(key as! String))
                                }
                                anomalyScore = max(score, anomalyScore)
                            }
                            
                            let instanceData = TaurusApplication.dataFactory.createInstanceData(instance_id, aggregation: AggregationType.Day, timestamp: dateSeconds, anomalyScore: Float(anomalyScore), metricMask: metricMask)
                            callback (instanceData)
                        }
                    }
                    query?.exclusiveStartKey =  results.lastEvaluatedKey
                    if (results.lastEvaluatedKey == nil){
                        done = true
                    }
                    return()
                } as AWSContinuationBlock)
                task?.waitUntilFinished() 
            } while !done
        
            callback (nil)
    }
    
    
    /** Get instance data for date range
        - parameter from: starting time
        - parameter to: ending time
        - parameter ascending : sort order
        - parameter callbab: will be called for each InstanceData
    */
    func  getAllInstanceData( _ from : Date,  to: Date,  ascending : Bool, callback:@escaping (InstanceData?)->Void? ) {
        var calendar =  Calendar(identifier:Calendar.Identifier.gregorian)
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
    
        let fromDay = (calendar as NSCalendar).ordinality(of: .day, in: .year, for: from)
        let toDay = (calendar as NSCalendar).ordinality(of: .day, in: .year, for: to)


        // Check if "from" date and "to" date falls on the same day
        if (fromDay == toDay) {
            print("getting instance data from today")
             getAllInstanceDataForDate(from, fromHour: (calendar as NSCalendar).component(NSCalendar.Unit.hour, from: from), toHour: (calendar as NSCalendar).component(NSCalendar.Unit.hour, from: to), ascending: ascending, callback : callback)
        } else {
            print("getting instance data from a different day")
            // Get Multiple days
            var totalDays = toDay - fromDay;
            // Account for intervals at the end of the year where fromDay could be greater than toDay
            if (totalDays < 0) {
                totalDays += 365;
            }
            var interval = -1;
            var date = to
            // Check if loading in reverse order
            if (ascending) {
                date = from;
                interval = 1;
            }
            for i in 0...totalDays {
               NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: DataSyncService.PROGRESS_STATE_EVENT), object: date)
                
               getAllInstanceDataForDate(date, fromHour:0, toHour: 23, ascending: ascending, callback : callback)
                
                // FIXME verify this handles end of year wrapping properly
               date = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: interval, to: date, options: [])!
            }
            
             NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: DataSyncService.PROGRESS_STATE_EVENT), object: nil)
        }
    }
}
