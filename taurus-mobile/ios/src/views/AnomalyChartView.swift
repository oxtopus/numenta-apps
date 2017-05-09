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


import UIKit
import Foundation

class AnomalyChartView: UIView {
    var label: String = ""
    var axisLabels = [String]()
    
    var data : [(Int64,Double)] = []
    var startDate : UInt64 = 0
    var endDate : UInt64 = 0
    
    var numYLabels: Int32 = 5
    var axisInterval : Double = 0.0
    var pointWidth = Double( 2.0 )
    var contentArea : CGRect = CGRect()
    var prompt :String?  = ""
    
    var barWidth = 10.0
    var barsOnChart  = 24
    var maxRange : Double = 0.0
    var minRange : Double = 0.0
    var paddingBottom : Double = 0.0
    
    var minPadding : Double = 5.0

    let leftMargin = 10.0
    
    /** init from interfact builder
    */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /** init from code
    */
    override init( frame : CGRect){
        super.init(frame: frame)
    }
    
    /** draw view
        parameter rect: rectangle to draw in
    */
    override func draw(_ rect: CGRect) {
        self.contentArea = rect
        
        drawValues( rect)
        drawFlags(rect)
        drawLabels (rect)
    }
   
    /** current not drawing labels*/
    func drawLabels(_ rect: CGRect){
    }
    
    /** get level for the value
        - parameter value : value to get level of
        - returns: level
    */
    func getLevel(_ value :Double)->Int{
        if (value.isNaN) {
            return 0
        }
        let intVal : Int  = max (abs(Int(value * 10000.0)), 500)
        return intVal
    }
    
    
    /** Draw values for level
        this could be optimized a bit by moving some of the init code out
    */
    func drawValues( _ rect: CGRect){
        let context = UIGraphicsGetCurrentContext()!
        
        context.saveGState()

        let emptyColor = UIColor.black
        
        
        var right =  Double(rect.width) -  leftMargin
        let barWidth = (right - leftMargin) / Double(TaurusApplication.getTotalBarsOnChart())
        
        var left = right - barWidth
        var bar : CGRect = CGRect()
        let emptyBarHeight  = 4.0
        
        bar.size.width = CGFloat(barWidth-2)
        bar.origin.y = rect.height
        
        // Draw the data from right to left
        for value in data.lazy.reversed(){
            if (right < barWidth){
                break
            }
            
            // values without dates represent folded bards
            if (value.1 == 0){
                // fixme
            }
         else if ( value.1.isNaN){
                context.setFillColor(emptyColor.cgColor)
            
                bar.origin.x = CGFloat(left)
                bar.size.height  = CGFloat(emptyBarHeight)
                context.addRect(bar)
            
                context.fillPath()
           
        }else{
                              var color : CGColor
              //  print (value.1)
                 bar.size.height  = -CGFloat(rect.height)
                let level = getLevel(DataUtils.logScale(value.1))
             //   print (level)
                if (level>=9000){
                    color = Appearence.redbarColor
                    bar.size.height += 12.0
                } else if (level>4000){
                    color = Appearence.yellowbarColor
                    bar.size.height += 17.0
                }else {
                   color = Appearence.greenbarColor 
                    bar.size.height += 26.0
                }
                
                context.setFillColor(color)
                
                bar.origin.x = CGFloat(left)+1.0
               
                context.addRect(bar)
                
                context.fillPath()
                
        }
            left -= barWidth
            right -= barWidth
        }
        context.restoreGState()
    }
    
    // Don't use currently
    func drawFlags( _ rect: CGRect ){
          }
    
    // Currently not used
    func  convertToPixel( _ value :Double)->Double {
        if value.isNaN{
            // Put invalid numbers outside the content area
            
            return Double(contentArea.maxY+100)
            
        }
        
        if (self.maxRange == self.minRange){
            return Double(contentArea.maxY) - self.paddingBottom
        }
        
        return Double(contentArea.maxY) - self.paddingBottom - (Double(contentArea.height-20) - self.paddingBottom) * (value - self.minRange) / (self.maxRange - self.minRange);
    }
    
    
    /** set data
        -parameter data: data to render
    */
    func setData(_ data:[(Int64,Double)]?){
        if (data != nil){
            self.data = data!
            refreshScale()
            self.setNeedsDisplay()
        }
    }
    
    // Calculate scale for data
    func refreshScale(){
       maxRange = 0
       minRange  = Double.infinity
        
        for element in data{
            maxRange = max (maxRange, element.1)
            minRange = min (minRange, element.1)
        }
        
        axisInterval = (maxRange-minRange)/Double(self.numYLabels)
        
        paddingBottom = minRange == 0 ? 0 : minPadding
    }
}
