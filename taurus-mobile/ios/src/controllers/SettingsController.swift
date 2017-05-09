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

import UIKit
/** Setting controller. Display and edit the user visible app settings
*/
class SettingsController: UITableViewController {
    
    @IBOutlet var refreshLabel: UILabel?
    @IBOutlet var versionLabel: UILabel?
    @IBOutlet var notificationLabel: UILabel?
    @IBOutlet var notificationSwitch: UISwitch?

    let sectionGeneral = 0
    let sectionNotifications = 1
    let sectionDataSouce = 2
    let refreshRateIndex = 1
    let maxNotificationsRateIndex = 1
    let dataSourceIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateVersionLabel()
        updateRefreshLabel()
        self.updateNotificationLabel()
        
        let enabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        notificationSwitch?.setOn(  enabled , animated: false )
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    /** Handle selection of a row
        - parameter tableView : table being selected
        - parameter didSelectRowIndexPath : path to selected index
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if ( indexPath.section == sectionGeneral && indexPath.item == refreshRateIndex){
            showRefreshPicker()
        }
        
        if ( indexPath.section == sectionNotifications && indexPath.item == maxNotificationsRateIndex){
            showNotificationPicker()
        }
        
        if (indexPath.section == sectionDataSouce && indexPath.item == dataSourceIndex){
            UIApplication.shared.openURL(URL(string: "http://www.xignite.com")!)
        }
    }

    /** Update the version label with version and build number from the main bundle
    */
    func updateVersionLabel(){
        let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let appBuildString =  Bundle.main.object( forInfoDictionaryKey: "CFBundleVersion") as! String
        let versionBuildString = String(format: "%@  (%@)", appVersionString, appBuildString)
        
        self.versionLabel?.text = versionBuildString
    }
    
    /** update enabled switch
    */
    @IBAction func notificationSwitch( _ sender: UIButton ){
        let defaults = UserDefaults.standard
        defaults.set(notificationSwitch!.isOn, forKey: "notificationsEnabled")
    }
    
    
    /** update refresh cell text
    */
    func updateRefreshLabel(){
        let defaults = UserDefaults.standard
        let frequency =  defaults.integer(forKey: "refreshFrequency")
        let actionString = String(format: "%d  minutes", frequency)
        self.refreshLabel?.text = actionString
    }
    
    /** update refresh cell text
    */
    func updateNotificationLabel(){
        let defaults = UserDefaults.standard
        let item =  defaults.integer(forKey: "maxNotificationsPerCompany")
        let actionString =  getActionString (item)
        
        self.notificationLabel?.text = actionString
    }
    
    /** show action sheet to select refresh frequency
    */
    func showRefreshPicker(){
        let optionMenu = UIAlertController(title: nil, message: "Refresh Rate", preferredStyle: .actionSheet)
        let frequency = [1,5,10,15,30]
        
        for item in frequency {
            
            let actionString = String(format: "%d  minutes", item)
            let action = UIAlertAction(title: actionString, style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                let defaults = UserDefaults.standard
                defaults.set(item, forKey: "refreshFrequency")
                
          
                let interval : TimeInterval  = Double(item) * 60.0
               
                // Request background sync frequency
                
                UIApplication.shared.setMinimumBackgroundFetchInterval(interval)
                self.updateRefreshLabel()
            })
            
            optionMenu.addAction(action)

        }
    
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    
    /** getActionString
        - parameter value: hourly limit
        - returns: formatted string
    */
    func getActionString ( _ value : Int )->String{
        var actionString = ""
        if (value == 0){
            actionString = "No limit"
        } else if (value == 1){
            actionString = "1 per hour"
        }else{
            actionString = String(format: "1 per %d  hours", value)
        }
        return actionString
    }
    
    /** show action sheet to select notification frequency    */
    func showNotificationPicker(){
        let optionMenu = UIAlertController(title: nil, message: "MaxNotifcationsPerCompany", preferredStyle: .actionSheet)
        let frequency = [0,1,2,8,24]
        
        for item in frequency {
            let actionString =  getActionString (item)
            let action = UIAlertAction(title: actionString, style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                let defaults = UserDefaults.standard
                defaults.set(item, forKey: "maxNotificationsPerCompany")
                
                self.updateNotificationLabel()
            })
            
            optionMenu.addAction(action)
        }
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "com.numenta.taurus.preference.SettingsActivity")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker?.send(builder?.build() as! [AnyHashable: Any])
    }
}
