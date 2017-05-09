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
import UIKit
/** Hold references to some of the display options like colors which should be shared accross fields
*/
class Appearence{
    static var redbarColor : CGColor = UIColor(red: 203.0/255.0, green: 0.0/255.0, blue: 0.0, alpha: 1.0).cgColor
    
     static var yellowbarColor : CGColor = UIColor(red: 214.0/255.0, green: 206.0/255.0, blue: 3.0/255, alpha: 1.0).cgColor
    
     static var greenbarColor : CGColor = UIColor(red: 16.0/255.0, green: 131.0/255.0, blue: 0.0, alpha: 1.0).cgColor
    
    static var lineChartColor : CGColor = UIColor(red: 42.0/255.0, green: 153.0/255.0, blue: 206.0/255.0, alpha: 1.0).cgColor
    
    static var viewMargin = 10.0
    
}
