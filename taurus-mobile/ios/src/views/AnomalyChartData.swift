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


protocol AnomalyChartData {

    /**
    * @return {@code true} if we have data, {@code false} otherwise
    */
    func hasData()->Bool
    
    /**
    * @return Display Name
    */
    func getName()->String;
    
    /**
    * Aggregated metric data, should be called after {@link #load()}
    */
    func getData()->[(Int64, Double)]?
    
    /**
    * @return The {@link AggregationType} used on this instance data
    */
    func getAggregation()->AggregationType;
    
    /**
    * Load metric data from the database
    *
    * @return {@code true} if got new data {@code false} otherwise
    */
    func load()->Bool
    
    /**
    * Clears memory cache, call {@link #load()} to reload data from the
    * database
    */
    func clear();
    
    /**
    * Load data up to this date, {@code null} for last known date
    *
    * @param endDate the endDate to set
    */
    func setEndDate( _ endDate : Date)
    
    /**
    * Load data up to this date, {@code null} for last known date
    *
    * @return the endDate
    */
    func getEndDate()->Date?
    
    /**
    * Instance or Metric ID represented by this data
    */
    func getId()->String
    
    /**
    * Get Metric Unit if available
    */
    func getUnit()->String?
    
    /**
    * This chart data type, "I" for instance or "M" for metric
    */
    func getType()->Character
    
    /**
    * Get all timestamps with annotations
    */
    func getAnnotations() ->[Int64]?
    
    /**
    * Return the overall rank for the data represented by this class.
    * Usually the rank is calculated as the sum of all anomaly score values
    */
    func getRank()->Float

    
    
}
