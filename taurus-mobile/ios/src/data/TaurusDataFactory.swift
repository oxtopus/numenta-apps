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


/**
* Factory used to create Taurus Data model Objects
*/
class TaurusDataFactory: CoreDataFactoryImpl {
    func createTweet(_ tweetId: String, aggregated: Date, created: Date, userId: String, userName: String, text: String, retweetCount: Int32) -> Tweet! {
        
        let aggreatedTime : Int64 =  Int64(aggregated.timeIntervalSince1970*1000)
        let createdTime : Int64 = Int64(created.timeIntervalSince1970*1000)
        
        return Tweet(id: tweetId, aggregated: aggreatedTime, created: createdTime, userId: userId, userName: userName, text: text, retweetTotal: retweetCount)
    }

    override func createInstanceData( _ cursor: FMResultSet!) -> InstanceData! {
        return TaurusInstanceData(cursor : cursor)
    }

    func createInstanceData(_ instanceId: String!, aggregation: AggregationType!, timestamp: Int64, anomalyScore: Float, metricMask: MetricType!) -> InstanceData! {
        return TaurusInstanceData( instanceId: instanceId, aggregation:  aggregation.minutes(), timestamp:  timestamp, anomalyScore: anomalyScore, metricMask: metricMask)
    }

    func createInstanceData(_ instanceId: String!, aggregation: AggregationType!, timestamp: Int64, anomalyScore: Float, metricMask: MetricType) -> InstanceData! {
        return TaurusInstanceData(instanceId : instanceId, aggregation:  aggregation.minutes(), timestamp: timestamp, anomalyScore : anomalyScore,  metricMask: metricMask)
    }

    func createNotification(_ instanceId: String!, timestamp: Int64, description: String!) -> Notification! {
        return TaurusNotification(instanceId,  timestamp: timestamp,  description: description)
    }
}
