

import Foundation
import UIKit

class LineChartView: UIView {
  //  var label: String = "Stock Price"
    var axisLabels = [String]()
    var anomalies = [(Int64, Double)]()
    var data : [Double] = []
    var numYLabels: Int32 = 3
    var axisInterval : Double = 0.0
    var pointWidth = Double( 2.0 )
    var contentArea : CGRect = CGRect()
    var barWidth : Double = 0.0
    var barMarginLeft = Appearence.viewMargin
    
    var wholeNumbers = true
    var maxValue : Double = 0.0
    var minValue : Double = 0.0
    var paddingBottom : Double = 0.0
    
    var minPadding : Double = 5.0
    var markerX = -1.0
    
    var emptyTextString : String?
    var isEmpty : Bool = false
    var selection = -1
    var selectOnDraw : Int64 = -1
    // Callback for when the chart is touched. The int is the index to the closest data element
    var selectionCallback :( (Int)->Void)?
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
       // setData()
       
    }
    
    override init( frame : CGRect){
        
        super.init(frame: frame)
     //   setData()
    }
    
    override func draw(_ rect: CGRect) {
      
        self.contentArea = rect
        
        if (data.count > 0){
            let contentWidth = Double (rect.width) - 2 * Appearence.viewMargin
            pointWidth =  Double(contentWidth)/Double(data.count)
            barWidth = Double (contentWidth) / Double(TaurusApplication.getTotalBarsOnChart())
            
        }
        
        if (selectOnDraw > 0){
           markerX = Double(selectOnDraw) * self.pointWidth + Double(barMarginLeft)
            selectOnDraw = -1
        }
        drawAnomalies(rect)
        drawMarker(rect)
        drawValues( rect)
        
     
    //    drawAxes (rect)
        drawYLabels (rect)

        
    }
    
    /** draw marker in response to user touches
        - parameter rect : drawing rectangle of the view
    */
    func drawMarker ( _ rect : CGRect){
        if (markerX<0){
            return
        }
        
        if (self.selectionCallback == nil){
            return
        }
        let context = UIGraphicsGetCurrentContext()!
        var bar : CGRect = CGRect()
        bar.origin.y = 0
        bar.size.height = rect.height
        bar.size.width = 6.0
        
        bar.origin.x = CGFloat(markerX)
        
        context.saveGState()
        context.setFillColor(UIColor.white.cgColor)
        context.addRect(bar)
        context.fillPath()
        context.restoreGState()
    }
    
    func drawAnomalies(_ rect: CGRect ){
        let context = UIGraphicsGetCurrentContext()!
        var bar : CGRect = CGRect()
 
        if (anomalies.count > 0) {
//          let top = contentArea.origin.y + contentArea.size.height / 2;
            let bottom = contentArea.size.height
            
            bar.size.width = CGFloat(barWidth-1)
            bar.origin.y = bottom-1

            for  value in anomalies {
                if (value.0 >= Int64(data.count)) {
                    continue; // Out of range
                }
                
                let left = Double(contentArea.origin.x) + barMarginLeft + pointWidth*Double(value.0)
                bar.size.height = -(contentArea.size.height/2-10)

                bar.origin.x =  CGFloat(left)
                               var color : CGColor
                
                let level = abs(value.1 * 10000.0)
                
                if (level>=9000){
                    color = Appearence.redbarColor
                    bar.size.height -= 10.0
                } else if (level>4000){
                    color = Appearence.yellowbarColor
                    bar.size.height -= 5.0
                }else {
//                   color = UIColor.greenColor().CGColor
//                    bar.size.height -= 4.0
                   continue
                }
       
                context.saveGState()
                context.setFillColor(color)
                context.addRect(bar)
                context.fillPath()
                context.restoreGState()
 
            }
            
        }
    }
    
    func getLevel(_ value :Double)->Int{
        if (value.isNaN) {
            return 0
        }
        var intVal : Int  = abs(Int( value * 10000.0))
        if (intVal<500)
        {
            intVal = 500
        }
        return intVal
    }
    
   
    
    func drawValues(_ rect: CGRect){
        let context = UIGraphicsGetCurrentContext()!
        
        context.saveGState()
        
        var points = [Double]()
        context.setLineWidth(2.0)
      //  let colorSpace = CGColorSpaceCreateDeviceRGB()
      //  let components: [CGFloat] = [0.0, 0.0, 1.0, 1.0]
        let color = Appearence.lineChartColor
        
        
        
        context.setStrokeColor(color)
        
        var x1,y1,x2,y2,y0 : Double

        if ( data.count == 0 )
        {
            return
        }
        
         points.append( Double(contentArea.origin.x) + Appearence.viewMargin )
         points.append( (convertToPixel(self.data[0])))
         points.append(  points[0]+pointWidth/2.0)
         points.append(  (convertToPixel(self.data[0])))
        
        context.move(to: CGPoint(x: CGFloat(points[0]), y: CGFloat(points[1])))
        context.addLine(to: CGPoint(x: CGFloat(points[2]), y: CGFloat(points[3])))
        
   
        for i in 1...data.count {
            x1 = points[ (i-1)*4+2]
            y1 = points[ (i-1)*4+3]

            
        
            x2 =  Double(contentArea.origin.x) + Appearence.viewMargin +    pointWidth / 2.0 + Double(i) * pointWidth
            y2 = convertToPixel(self.data[i])
            
            if (data[i].isNaN){
                  // Don't move the Y axis. The line will not be drawn, see #convertToPixel
                y1 = y2
            } else if ( data[i-1].isNaN){
                if ( i == 1){
                    y0 = y2
                } else{
                    // Two consecutive missing values
                    if (data[i - 2].isNaN) {
                        y0 = y2;
                    } else {
                        // Get previous data point
                        y0 = points[(i - 2) * 4 + 3]
                    }

                }
                y1 = y0 + (y2-y0) / 2.0
            }
           
            points.append(x1)
            points.append(y1)
            points.append(x2)
            points.append(y2)
           // print (x2)
            context.move(to: CGPoint(x: CGFloat(x1 ), y: CGFloat(y1)))
           //  CGContextMoveToPoint(context, CGFloat(x2 ), CGFloat(rect.height))
               context.addLine(to: CGPoint(x: CGFloat( x2 ), y: CGFloat( y2)))
                   }

        context.strokePath()
        context.restoreGState()
    }
    
    func drawAxes( _ rect: CGRect ){
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.saveGState()
        
        context?.setLineWidth(2.0)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let components: [CGFloat] = [1.0, 1.0, 1.0, 1.0]
        let color = CGColor(colorSpace: colorSpace, components: components)
        context?.setStrokeColor(color!)
        
        
        context?.move(to: CGPoint(x: rect.origin.x, y: 0))
        context?.addLine(to: CGPoint(x: rect.origin.x, y: rect.height))
        context?.addLine(to: CGPoint(x: rect.origin.x+rect.width, y: rect.height))
        
        context?.strokePath()
        context?.restoreGState()
    }
    
    func drawYLabels (_ rect: CGRect){
        
        if (self.isEmpty){
            if (self.emptyTextString == nil){
                return
            }
            let context = UIGraphicsGetCurrentContext()
            
            let fieldColor: UIColor = UIColor.white
           
            let font = UIFont.boldSystemFont(ofSize: 16.0)

            
            context?.saveGState()
            
            let size = self.emptyTextString?.size(attributes: [NSFontAttributeName : font,  NSForegroundColorAttributeName: fieldColor])
            let x = rect.width/2 - size!.width/2
            let top =  rect.height/2 - size!.height/2
            self.emptyTextString?.draw(at: CGPoint(x: x, y: top),
                withAttributes: [NSFontAttributeName : font,  NSForegroundColorAttributeName: fieldColor])
            
        
        
            context?.restoreGState()
            return
        }
        let context = UIGraphicsGetCurrentContext()
        
        let fieldColor: UIColor = UIColor.white
       // let fontName = "System-Bold"
        let font: UIFont = UIFont.boldSystemFont(ofSize: 12.0)
        
        context?.saveGState()
        var s: String = "1.0"
        
        var decimals = 0
        if ( axisInterval<1 && axisInterval > 0 ){
            decimals = Int(ceil (-log10(axisInterval)))
        }
        
        for i in 0...self.numYLabels {
            let y = self.minValue+self.axisInterval*Double(i)
            
            s = DataUtils.formatDouble ( y, numDecimals: decimals)!
            
            let labelTop = convertToPixel(y) - Double( font.lineHeight)
            
            s.draw(at: CGPoint(x: CGFloat( self.barMarginLeft), y: CGFloat( labelTop)),
                withAttributes: [NSFontAttributeName : font,  NSForegroundColorAttributeName: fieldColor])
            
        }
        
        context?.restoreGState()


    }
    
    func  convertToPixel( _ value :Double)->Double {
    
        if value.isNaN{
            // Put invalid numbers outside the content area

            return  Double(contentArea.height+100)
            
        }
        
        if (self.maxValue == self.minValue){
            return Double(contentArea.maxY) - self.paddingBottom
        }

        let viewHeight = contentArea.height
        return Double( Double(viewHeight) - Double(viewHeight - 15 ) * (value - self.minValue) / (self.maxValue - self.minValue))
    }
    

    func updateData(){
        self.isEmpty = true
        for value in self.data {
            if (value.isNaN  == false){
                isEmpty = false
                break
            }
        }
        refreshScale()
        self.setNeedsDisplay()
    }
    
    func refreshScale(){
        
        maxValue = -1
        minValue = Double.infinity
        for val in data{
            if (val.isNaN == false ){
                if val > maxValue{
                    maxValue = val
                }
                if val  < minValue{
                    minValue = val
                }
            }
        }
        
        if (self.wholeNumbers ){
             axisInterval = ceil((maxValue-minValue)/Double(self.numYLabels))
        } else{
            axisInterval = (maxValue-minValue)/Double(self.numYLabels)
        }
        
        paddingBottom = minValue == 0 ? 0 : minPadding
    }
    
    /** Detect touches on the chart and report them to the selection listener
        - parameter touches:
        - parameter event:
    */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
       
        if let touch = touches.first {
            let x = Double(touch.location(in: self).x)
            if (x != markerX){
                markerX = Double(x)
                
                selection = Int ( (markerX) / self.pointWidth)
                if ( self.selectionCallback != nil){
                    selectionCallback! (selection)
                }
                self.setNeedsDisplay()
            }
        }
        
        super.touchesBegan(touches, with:event)
    }
    
    func selectIndex ( _ index : Int64){
        markerX = Double(index) * self.pointWidth + Double(barMarginLeft)
        self.setNeedsDisplay()
    }
}
