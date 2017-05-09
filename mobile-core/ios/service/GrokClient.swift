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
  /**
  * <code>GrokClient</code> interface wraps a connection to the Grok REST API
  */
public protocol GrokClient {

    func isOnline() -> Bool
    func login()
    func getServerUrl() -> String!
    func getServerName() -> String!
    func getServerVersion() -> Int
    func getMetrics() -> [Metric?]!
    func getMetricData(_ modelId: String!, from: Date!, to: Date!, callback: (MetricData!)->Bool!)
    func getNotifications() -> [Notification?]!
    func acknowledgeNotifications(_ ids: [String?]!)
    func getAnnotations(_ from: Date!, to: Date!) -> [Annotation?]!
    func deleteAnnotation(_ annotation: Annotation!)
    func addAnnotation(_ timestamp: Date!, server: String!, message: String!, user: String!) -> Annotation!
}
