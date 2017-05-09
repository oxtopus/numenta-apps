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
* Represent Stock market open hours and holidays
*/
open class MarketCalendar {

    static let JANUARY = 1
    static let FEBRUARY = 2
    static let MARCH = 3
    static let APRIL = 4
    static let MAY = 5
    static let JUNE = 6
    static let JULY = 7
    static let AUGUST = 8
    static let SEPTEMBER = 9
    static let OCTOBER = 10
    static let NOVEMBER = 11
    static let DECEMBER = 12

    var workweek = [ false,true, true, true, true, true, false]
    
    var holidays  = [Int64: Int64]() // first number is floored to lowest 24 hours. The next is closing time
    
     init(){
        createHolidays()
    }
    /** determine if the market is open
    */
    open func isOpen (_ date : Date)->Bool {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "US/Eastern")!

        
        
        // check day of week
        let dayOfWeek = (calendar as NSCalendar).components( (NSCalendar.Unit.weekday), from: date)
        
        if ( workweek[ dayOfWeek.weekday! - 1 ]==false){
            return false
        }
        
        let comp = (calendar as NSCalendar).components((NSCalendar.Unit.hour), from: date)
        let hour = comp.hour
        if (hour!>=9 && hour!<16)
        {
            let timestamp = DataUtils.timestampFromDate(date)
            let flooredTime = DataUtils.floorToDay(timestamp)
            
            let holidayDatestamp = holidays[flooredTime]
            
            if ( holidayDatestamp != nil){
                if ( timestamp > holidayDatestamp!){
                    return false
                }
                
            }
            return true
        }
        
       
        return false
    }
    
    open func isOpen (_ date : Int64)->Bool {
        let time = DataUtils.dateFromTimestamp(date)
        return isOpen(time)
    }
    
    /**
        Add in all the holidays
    */
    open func createHolidays(){
        // New Years Day
        addHoliday(2015, month: MarketCalendar.JANUARY, day: 1, closingHour:0)
        addHoliday(2016, month: MarketCalendar.JANUARY, day: 1, closingHour:0)
        
        
        // Martin Luther King, Jr. Day
        addHoliday(2015, month: MarketCalendar.JANUARY, day: 19, closingHour:0)
        addHoliday(2016, month: MarketCalendar.JANUARY, day: 18, closingHour:0)
        
        // President's Day
        addHoliday(2015, month: MarketCalendar.FEBRUARY, day: 16, closingHour:0)
        addHoliday(2016, month: MarketCalendar.FEBRUARY, day: 15, closingHour:0)
        
        
        // Good Friday
        addHoliday(2015, month: MarketCalendar.APRIL, day: 3, closingHour:0)
        addHoliday(2016, month: MarketCalendar.MARCH, day: 25, closingHour:0)
       
        
        // Memorial Day
        addHoliday(2015, month: MarketCalendar.MAY, day: 25, closingHour:0)
        addHoliday(2016, month: MarketCalendar.MAY, day: 30, closingHour:0)
       
        
        // Independence Day
        addHoliday(2015, month: MarketCalendar.JULY, day: 3, closingHour:0)
        addHoliday(2016, month: MarketCalendar.JULY,day:  4, closingHour:0)
        
        
        // Labor Day
        addHoliday(2015, month: MarketCalendar.SEPTEMBER, day: 7, closingHour:0)
        addHoliday(2016, month: MarketCalendar.SEPTEMBER, day: 5, closingHour:0)
       
        
        // Thanksgiving Day
        addHoliday(2015,month: MarketCalendar.NOVEMBER, day: 26, closingHour:0)
      
        addHoliday(2015, month: MarketCalendar.NOVEMBER, day: 27, closingHour:13)
        addHoliday(2016, month: MarketCalendar.NOVEMBER, day: 24,closingHour: 0)
        addHoliday(2016, month: MarketCalendar.NOVEMBER, day: 25, closingHour:13)
        
        // Christmas
        addHoliday(2015, month: MarketCalendar.DECEMBER, day: 24, closingHour:13)
        addHoliday(2015,month: MarketCalendar.DECEMBER, day: 25, closingHour:0)
        addHoliday(2016, month: MarketCalendar.DECEMBER, day: 26, closingHour: 0)
       
    }
    
    /** Add holiday to holiday dictionary
        - parameter year:
        - parameter month:
        - parameter day:
        - parameter closingHour:
    */
    func addHoliday( _ year: Int, month: Int, day:Int, closingHour: Int){
        let calendar =  Calendar.current
        
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = closingHour
        (comps as NSDateComponents).timeZone = TimeZone(identifier: "US/Eastern")
        
        let holidayDate = calendar.date(from: comps)
        let holidayTimestamp = DataUtils.timestampFromDate(holidayDate!)
        holidays [ DataUtils.floorToDay(holidayTimestamp)] = holidayTimestamp
        
    }
    
    
    

}
