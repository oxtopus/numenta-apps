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


import UIKit


class TwitterEntry {
    var tweets: Int32 = 0
    var data = [Tweet]()
}


class TwitterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    @IBOutlet var timeSlider: TimeSliderView?
    @IBOutlet weak var instanceTable: UITableView!
    @IBOutlet weak var anomalyChartView: AnomalyChartView!
    @IBOutlet weak var metricChartView: LineChartView!
    @IBOutlet weak var ticker: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var condensedToggle: UISwitch?


    var timeToSelect: Int64 = 0
    var twittermap = [Int64: TwitterEntry]()
    var twitterIndex = [Int64]()
    var showCondensed = true
    var cancelLoad = false
    var  metricChartData: MetricAnomalyChartData?
    var _aggregation: AggregationType = TaurusApplication.getAggregation()
    var metricChartDataLoading = false

    // Serial queue for loading chart data
    // let loadQueue = dispatch_queue_create("com.numenta.TwitterController", nil)

    var chartData: InstanceAnomalyChartData? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    /** handle the UISwitch for condensed tweets
     */
    @IBAction func toggleCondensed() {
        self.showCondensed = (condensedToggle?.isOn)!
        self.instanceTable.reloadData()

        if (self.showCondensed) {
            self.instanceTable.separatorColor =  UIColor.black
        } else {
            self.instanceTable.separatorColor = UIColor.lightGray
        }
    }

    /** bind data to view
     */
    func configureView() {
        if chartData == nil {
            return
        }

        if chartData?.getEndDate() != nil {
            timeSlider?.endDate = (chartData?.getEndDate()!)!
        }
        anomalyChartView?.setData (chartData!.getData())
        ticker?.text = chartData?.ticker
        name?.text = chartData?.name

        if metricChartData != nil {
            if metricChartData?.rawData == nil {
                if metricChartDataLoading == false {
                    metricChartDataLoading = true
                    let priority = DispatchQoS.QoSClass.userInitiated

                    DispatchQueue.global(qos: priority).async {

                        self.metricChartData!.load()
                        self.metricChartData!.collapsed = false
                        self.metricChartData!.refreshData()

                        if self.metricChartData!.rawData != nil {
                            DispatchQueue.main.async {

                                self.metricChartView?.data  = self.metricChartData!.rawData!
                                self.metricChartView?.anomalies = self.metricChartData!.data!
                                self.metricChartView?.updateData()

                                DispatchQueue.global(qos: priority).async {
                                    self.loadTwitterData()
                                }
                            }
                        }
                    }
                }
            } else {
                metricChartData!.collapsed = false
                metricChartData!.refreshData()
                metricChartView?.data  = metricChartData!.rawData!
                metricChartView?.anomalies = metricChartData!.data!
                metricChartView?.updateData()
            }
        }

        if self.timeToSelect > 0 {
            let index  = Int64(metricChartView!.data.count) - ((metricChartData?.endDate)!+DataUtils.MILLIS_PER_HOUR  - timeToSelect)/DataUtils.METRIC_DATA_INTERVAL
            self.metricChartView.selectOnDraw = index
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        timeSlider?.showBottom = false
        timeSlider?.transparentBackground = true

        // on iOS 8+ need to make sure table background is clear
        instanceTable.backgroundColor = UIColor.clear
        self.instanceTable.estimatedRowHeight = 80.0
        self.instanceTable.rowHeight = UITableViewAutomaticDimension
        let menuIcon = UIImage(named: "menu")
        let b2 = UIBarButtonItem(image: menuIcon, style: UIBarButtonItemStyle.plain, target: self, action: #selector(TwitterViewController.showMenu(_:)))
        self.menuButton = b2
        self.navigationItem.rightBarButtonItems = [menuButton!]

        metricChartView.selectionCallback = self.selection
        condensedToggle?.isOn = self.showCondensed
        self.instanceTable.separatorColor = UIColor.black
        configureView()

        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "EEE M/d"

        let dateString = dayTimePeriodFormatter.string(from: self.timeSlider!.endDate as Date)

        self.date?.text = dateString

        let priority = DispatchQoS.QoSClass.userInitiated
        DispatchQueue.global(qos: priority).async {
            self.loadTwitterData()
        }
    }

    func showMenu(_ sender: UIButton) {
        CustomMenuController.showMenu( self)
    }

    // Dispose of any resources that can be recreated.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /** Datasource delegate
     - returns : number of sections in table
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return twitterIndex.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  cell = tableView.dequeueReusableCell(withIdentifier: "TwitterHeaderCell")
        let headerCell = cell as! TwitterHeaderCell
        let ts = twitterIndex [section]
        let date = DataUtils.dateFromTimestamp(ts)
        let twitterEntry = twittermap[ts]
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"

        headerCell.date.text = formatter.string(from: date)
        headerCell.tweetTotal.text = String(twitterEntry!.tweets)
        return headerCell
    }


    /** Datasource delegate to return number of rows in a cell.
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let tsIndex = twitterIndex[section]
        let twitterEntry = twittermap[tsIndex]
        if twitterEntry == nil {
            return 0
        }
        let items: [Tweet] = twitterEntry!.data

        return items.count
    }

    /** bind data to cell and return the cell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: TwitterCell? = self.instanceTable.dequeueReusableCell(withIdentifier: "TwitterCell") as! TwitterCell?

        let section = indexPath.section
        let tsIndex = twitterIndex[section]

        let twitterEntry = twittermap[tsIndex]

        let items: [Tweet]? = twitterEntry!.data
        let tweet = items![ indexPath.item]

        cell?.timestamp = tsIndex
        cell?.selectionStyle = .none

        if showCondensed {
            let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14.0)]
            let attrStr = NSMutableAttributedString(string: tweet.cannonicalText, attributes:attrs)
            if tweet.hasLinks {
                let bodyAttrs = [NSFontAttributeName : UIFont.systemFont(ofSize: 14.0)]
                let tweetText = NSMutableAttributedString(string: " links", attributes:bodyAttrs)
                attrStr.append(tweetText)

            }

            cell?.label?.attributedText = attrStr
            cell?.retweetCount.isHidden = true
            cell?.retweetImage.isHidden = true
            cell?.retweetTotal.isHidden = true

            if tweet.retweetCount > 1 {
                cell?.retweetCount.isHidden = false
                cell?.retweetCount.text = String(tweet.retweetCount)
            } else {
                cell?.retweetCount.isHidden = true
            }
        } else {
            let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0)]
            let attrStr = NSMutableAttributedString(string:"@" + tweet.userName, attributes:attrs)
            let bodyAttrs = [NSFontAttributeName: UIFont.systemFont(ofSize: 14.0)]
            let tweetText = NSMutableAttributedString(string: "\r\n" + tweet.text, attributes:bodyAttrs)
            attrStr.append(tweetText)
            cell?.label?.attributedText = attrStr

            if tweet.retweetCount > 1 {
                cell?.retweetCount.isHidden = false
                cell?.retweetCount.text = String(tweet.retweetCount)
            } else {
                cell?.retweetCount.isHidden = true
            }

            if (tweet.retweetCount > 1 || tweet.retweetTotal > 1) {
                cell?.retweetImage.isHidden = false
            } else {
                cell?.retweetImage.isHidden = true
            }

            if tweet.retweetTotal > 1 {
                cell?.retweetTotal.isHidden = false
                cell?.retweetTotal.text = String(tweet.retweetTotal)
            } else {
                cell?.retweetTotal.isHidden = true
            }
        }
        return cell!
    }

    /** prompt the user if they want to open the tweet when a row is selected
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let alertView = UIAlertController(
            title: "Open Twitter",
            message: "Are you sure you want to open this message using twitter?",
            preferredStyle: .alert)
        let section = indexPath.section
        let tsIndex = self.twitterIndex[section]
        let twitterEntry = self.twittermap[tsIndex]
        let items: [Tweet]? = twitterEntry!.data
        let tweet = items![ indexPath.item]
        let uri = "http://twitter.com/" + tweet.userName + "/status/" + tweet.id

        alertView.addAction(UIAlertAction(title: "Open", style: .default, handler: { (alertAction) -> Void in
            UIApplication.shared.openURL(URL(string: uri)!)
        }))
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertView, animated: true, completion: nil)
    }

    /** load twitter data
     fixme - do the more optimal load
     */
    func loadTwitterData() {

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let client = TaurusApplication.connectToTaurus()
        let metric = metricChartData?.metric
        let endTime = metricChartData!.getEndDate()// + DataUtils.MILLIS_PER_HOUR
        let start = DataUtils.timestampFromDate(endTime!) - DataUtils.MILLIS_PER_HOUR * Int64(TaurusApplication.getTotalBarsOnChart())
        let startDate = DataUtils.dateFromTimestamp(start)
        var lastTime: Int64 = 0
        var lastEntry: TwitterEntry?
        var loadIntervals = [(startDate, endTime!)]
        let values = metricChartData?.rawData
        var timeOffset: Int64  = 0
        var count = 0
        var numOfEntries = 25 // start small to be responsive
        var intervalEnd = endTime!

        if values != nil {
            loadIntervals.removeAll()
            for val in values! {
                if val.isNaN == false {
                    count += Int(val)
                }
                timeOffset += DataUtils.METRIC_DATA_INTERVAL
                if count > numOfEntries {
                    let intervalStart = DataUtils.dateFromTimestamp(DataUtils.timestampFromDate(intervalEnd) - timeOffset)
                    loadIntervals.append((intervalStart, intervalEnd))
                    intervalEnd = intervalStart
                    // Load more entries to reduce networking overhead
                    numOfEntries  = 250
                    count = 0
                    timeOffset = 0
                }
            }
            loadIntervals.append((startDate, intervalEnd))
        }

        for entry in loadIntervals {
            if self.cancelLoad {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }

            client?.getTweets((metric?.getName())!, from: entry.0, to: entry.1 ) { (tweet: Tweet?) in
                if tweet != nil {
                    let aggregationTime: Int64 = tweet!.aggregated
                    if aggregationTime != lastTime {
                        if lastEntry != nil {
                            self.sortTwitterEntry(lastEntry!)
                            self.twittermap[lastTime] = lastEntry
                        }

                        lastEntry = TwitterEntry()
                        lastTime = aggregationTime
                    }
                    let twitterEntry = lastEntry
                    var dup  = false
                    for existingTweet in twitterEntry!.data {
                        if existingTweet.cannonicalText == tweet!.cannonicalText {
                            if existingTweet.retweetCount == 0 {
                                existingTweet.retweetCount = 1
                            }
                            existingTweet.retweetCount += 1
                            dup = true
                            break
                        }
                    }
                    if dup == false {
                        twitterEntry?.data.append(tweet!)
                    }
                    twitterEntry?.tweets += 1
                }
                return nil
            }

            if lastEntry != nil {
                sortTwitterEntry(lastEntry!)
                self.twittermap[lastTime] = lastEntry
            }
            updateList()
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func sortTwitterEntry(_ twitterEntry: TwitterEntry) {
        // FIXME: 11-24-2015 Don't use sort in place since it causes crashes with large datasets.
        // XCode Bug has been reported to apple and looks like it is fixed in beta compilers
        twitterEntry.data =  twitterEntry.data.sorted {
            if $0.aggregated != $1.aggregated {
                return $0.aggregated > $1.aggregated
            }

            if $0.retweetCount != $1.retweetCount {
                return $0.retweetCount > $1.retweetCount
            }

            if $0.retweetTotal != $1.retweetTotal {
                return $0.retweetTotal > $1.retweetTotal
            }

            return  $0.id < $1.id
        }
    }

    func updateList() {

        /*  for twitterEntry  in self.twittermap.values {
        twitterEntry.data.sortInPlace{
        if ( $0.aggregated != $1.aggregated){
        return $0.aggregated > $1.aggregated
        }


        if ( $0.retweetCount != $1.retweetCount){
        return $0.retweetCount > $1.retweetCount
        }

        if ( $0.retweetTotal != $1.retweetTotal){
        return $0.retweetTotal > $1.retweetTotal
        }


        return  $0.id < $1.id

        }

        }*/


        // Update the table to the new data
        DispatchQueue.main.async {

            self.twitterIndex = Array(self.twittermap.keys)
            self.twitterIndex.sort {
                return $0 >  $1
            }

            // need to sort each bucket
            self.instanceTable?.reloadData()

            // Update selection
            if self.timeToSelect > 0 {
                let section  = self.getSectionByTimestamp(self.timeToSelect)
                let index = IndexPath(row: 0, section: section)
                self.instanceTable?.selectRow(at: index, animated: false, scrollPosition: UITableViewScrollPosition.top)
            }
        }
    }

    func  getSectionByTimestamp(_ timestamp: Int64) -> Int {
        var section = 0
        for val in twitterIndex {
            if val < timestamp {
                break
            }
            section += 1
        }

        if section >= twitterIndex.count {
            section = twitterIndex.count - 1
        }
        return section
    }

    /** Scroll table to match the selection
     - parameter index: */
    func selection( _ index: Int)->Void {

        if (metricChartData == nil || metricChartData!.rawData == nil) {
            return
        }
        let numIndexes =  Int64(metricChartData!.rawData!.count)
        let timeStamp = metricChartData!.endDate + DataUtils.MILLIS_PER_HOUR  -  (numIndexes-index) * DataUtils.METRIC_DATA_INTERVAL
        if twitterIndex.count <= 0 {
            return
        }

        let section = getSectionByTimestamp(timeStamp)
        let index = IndexPath(row: 0, section: section)
        self.instanceTable?.selectRow(at: index, animated: false, scrollPosition: UITableViewScrollPosition.top)
    }

    /** When the view is scrolled, update the metric chart selection
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleCells = self.instanceTable.visibleCells

        // If there are no visible cells don't do anything
        if visibleCells.count <= 0 {
            return
        }

        var time: Int64 = 0
        for cell in visibleCells {
            let twitterCell = cell as! TwitterCell
            if twitterCell.timestamp > time {
                time = twitterCell.timestamp
            }
        }

        let index  = Int64(metricChartView!.data.count) - ((metricChartData?.endDate)!+DataUtils.MILLIS_PER_HOUR  - time)/DataUtils.METRIC_DATA_INTERVAL
        self.metricChartView.selectIndex(index)
    }
    
    /**
     tell any pending chart to stop loading if the view is going away
     */
    override func viewWillDisappear(_ animated: Bool) {
        self.cancelLoad = true
        super.viewWillDisappear (animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "com.numenta.taurus.twitter.TwitterDetailActivity")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker?.send(builder?.build() as! [AnyHashable: Any])
    }
}
