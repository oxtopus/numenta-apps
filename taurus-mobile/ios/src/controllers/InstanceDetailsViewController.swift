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

class InstanceDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var timeSlider: TimeSliderView?
    @IBOutlet weak var instanceTable: UITableView!
    @IBOutlet weak var anomalyChartView: AnomalyChartView!
    @IBOutlet weak var marketHoursSwitch: UISwitch?
    @IBOutlet weak var ticker: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var menuButton: UIBarButtonItem!

    // Serial queue for loading chart data
    let loadQueue = DispatchQueue(label: "com.numenta.InstanceDetailsController", qos: .userInitiated, target: .global())
    var  metricChartData  = [MetricAnomalyChartData]()
    var _aggregation: AggregationType = TaurusApplication.getAggregation()
    var marketHoursOnly = true

    var chartData: InstanceAnomalyChartData? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    /*
     tell any pending chart to stop loading if the view is going away
     */
    override func viewWillDisappear(_ animated: Bool) {
        for chartData in metricChartData {
            chartData.stopLoading()
        }
        super.viewWillDisappear (animated)
    }

    /** bind data to view
     */
    func configureView() {
        if chartData == nil {
            return
        }

        if chartData?.getEndDate() != nil && timeSlider != nil {
            updateTimeSlider ( (chartData?.getEndDate()!)! as Date)
        }

        timeSlider?.disableTouches = false

        updateAnomalyChartView()

        ticker?.text = chartData?.ticker
        name?.text = chartData?.name

        metricChartData.removeAll()
        for metric in chartData!.metrics! {
            metricChartData.append( MetricAnomalyChartData (metric: metric, endDate :0))
        }

        metricChartData.sort {
            let left = MetricType.enumForKey($0.metric.getUserInfo("metricType")).rawValue
            let right = MetricType.enumForKey($1.metric.getUserInfo("metricType")).rawValue

            return left < right
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.


        // Hook up swipe gesture

        let panRec = UIPanGestureRecognizer()
        panRec.addTarget(self, action: #selector(InstanceDetailsViewController.draggedView(_:)))
        timeSlider?.addGestureRecognizer(panRec)
        timeSlider?.showBottom = false
        timeSlider?.transparentBackground = true
        timeSlider?.openColor = UIColor.clear.cgColor
        timeSlider?.closedColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.25).cgColor

        // on iOS 8+ need to make sure table background is clear
        instanceTable.backgroundColor = UIColor.clear
        instanceTable.rowHeight = 100

        let menuIcon = UIImage(named: "menu")

        let b2 = UIBarButtonItem (image: menuIcon,
                                  style: UIBarButtonItemStyle.plain,
                                 target: self,
                                 action: #selector(InstanceDetailsViewController.showMenu(_:)))

        self.menuButton = b2

        b2.tintColor = UIColor.white

        self.navigationItem.rightBarButtonItems = [ menuButton!]


        marketHoursSwitch?.isOn = self.marketHoursOnly
        self.timeSlider?.collapsed =  self.marketHoursOnly

        configureView()
        //loadQueue.async(execute: { self.loadQueue.setTarget(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated))})
    }

    func updateAnomalyChartView() {
        if marketHoursOnly {
            anomalyChartView?.setData (chartData!.getCollapsedData())
        } else {
            anomalyChartView?.setData (chartData!.getData())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func toggleMarketHours() {
        self.marketHoursOnly = marketHoursSwitch!.isOn
        self.timeSlider?.collapsed =  self.marketHoursOnly
        self.timeSlider?.setNeedsDisplay()

        updateAnomalyChartView()

        let visibleCells = self.instanceTable.visibleCells
        for cell in visibleCells {
            let metricCell = cell as! MetricCell
            if metricCell.data != nil {

                metricCell.data?.collapsed = self.marketHoursOnly
                metricCell.data?.refreshData()

                metricCell.chart.data  = metricCell.data!.rawData!
                metricCell.chart.anomalies = metricCell.data!.data!
                metricCell.chart.updateData()
                metricCell.setNeedsDisplay()
            }
        }
    }

    /**
     Handle the swipe gesture. Updates the time slider, anomalychart, and the metric table
     - parameter sender:
     */
    func draggedView(_ sender: UIPanGestureRecognizer) {
        //  self.view.bringSubviewToFront(sender.view)
        let translation = sender.translation(in: self.view)
        //  print (translation)
        if abs(translation.y) > abs(translation.x) {
            return
        }
        let distance = getDistance( Double( translation.x) * -1.0 )
        sender.setTranslation(CGPoint.zero, in: self.view)

        var newTime: Date?

        if self.marketHoursOnly {
            if self.chartData == nil {
                return
            }
            let pixelsPerBar = self.view.frame.size.width / CGFloat(TaurusApplication.getTotalBarsOnChart())

            let pDistance = Int(translation.x * -1.0)/Int(pixelsPerBar)
            var bars = self.chartData!.getData()
            if pDistance < 0 {
                // Scolling backwars
                let maxIndex: Int  = (bars?.count)! + pDistance  - 1
                var pos = max (0, maxIndex)
                var time = bars![pos].0

                while TaurusApplication.marketCalendar.isOpen (time) == false {
                    pos = pos - 1
                    if pos < 0 {
                        break
                    }
                    time = bars![pos].0
                }
                newTime = DataUtils.dateFromTimestamp( time )

            } else {
                // scrolling forward
                var time = bars![bars!.count - 1].0
                    + pDistance * Int(chartData!.getAggregation().milliseconds())
                while TaurusApplication.marketCalendar.isOpen (time) == false {
                    time = time + chartData!.getAggregation().milliseconds()
                }
                newTime = DataUtils.dateFromTimestamp( time )
            }

        } else {
            newTime =  timeSlider?.endDate.addingTimeInterval(distance) as! Date
        }

        //   print ((timeSlider?.endDate,newTime))

        var flooredDate = DataUtils.floorTo5Mins (newTime!)
        let endDateInd = DataUtils.timestampFromDate(flooredDate)
        let maxDate = DataUtils.floorTo5minutes(TaurusApplication.getDatabase().getLastTimestamp())
        let minDate = maxDate - (Int64(TaurusApplication.getNumberOfDaysToSync() - 1)) * DataUtils.MILLIS_PER_DAY
        // Check max date and no date
        if endDateInd > maxDate {
            flooredDate =  DataUtils.dateFromTimestamp(  maxDate )
        }
        // Check min date
        if endDateInd < minDate {
            flooredDate =  DataUtils.dateFromTimestamp(  minDate )
        }

        updateTimeSlider (flooredDate)
        chartData?.setEndDate(flooredDate)
        chartData?.load()

        updateAnomalyChartView()

        let visibleCells = self.instanceTable.visibleCells
        for cell in visibleCells {
            let metricCell = cell as! MetricCell

            if metricCell.data != nil {
                metricCell.data?.setEndDate (flooredDate)
                metricCell.data?.collapsed = self.marketHoursOnly
                metricCell.data?.refreshData()

                metricCell.chart.data  = metricCell.data!.rawData!
                metricCell.chart.anomalies = metricCell.data!.data!
                metricCell.chart.updateData()
                metricCell.setNeedsDisplay()
            }
        }
    }

    /** Update timeslider view to match the passed in date
     - parameter date: end date to show
     */
    func updateTimeSlider ( _ date: Date) {
        timeSlider?.endDate =  date
        timeSlider?.setNeedsDisplay()

        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "EEE M/d"

        let dateString = dayTimePeriodFormatter.string(from: date)

        self.date?.text = dateString
    }

    func showMenu( _ sender: UIButton) {
        CustomMenuController.showMenu( self)
    }

    /* get the amount of time to shift
     -parameter distance: length of swipe
     */
    func getDistance(_ distance: Double) -> Double {
        let width =  self.view.frame.size.width
        let pixels = Double(Double(width) / (Double)(TaurusApplication.getTotalBarsOnChart()))
        let scrolledBars = Double(Int64 (distance / pixels))
        // Scroll date by aggregation interval
        let interval = Double(TaurusApplication.getAggregation().milliseconds())/1000.0
        let timeDistance = Double(interval * scrolledBars)*(1.0)
        return timeDistance
    }

    /* Datasource delegate
     - returns : number of sections in table
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /* header title
     */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    /* Datasource delegate to return number of rows in a cell.
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metricChartData.count
    }

    /* bind data to cell and return the cell
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.instanceTable.dequeueReusableCell(withIdentifier: "metricCell")

        cell?.selectionStyle = UITableViewCellSelectionStyle.none
        let metricCell =  cell    as! MetricCell?

        if metricCell == nil {
            return metricCell!
        }

        metricCell?.chart.emptyTextString = "Market Closed"
        metricCell?.backgroundColor = UIColor.clear
        //    metricCell?.selectionStyle =   UITableViewCellSelectionStyle.Blue
        //    metricCell?.userInteractionEnabled = true

        let cellData =  metricChartData[ indexPath.item]

        metricCell?.label.text = cellData.getName()

        let type = MetricType.enumForKey(cellData.metric.getUserInfo("metricType"))
        if type == MetricType.StockPrice {
            metricCell?.chart?.wholeNumbers = false
        } else {
            metricCell?.chart?.wholeNumbers = true
        }

        if type == MetricType.TwitterVolume {
            metricCell?.prompt.text = "tap for details"
        }


        loadChartData( metricCell!, data: cellData)
        return cell!
    }

    /* Handle selection of row

     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cellData =  metricChartData[ indexPath.item]

        if MetricType.enumForKey(cellData.metric.getUserInfo("metricType")) == MetricType.TwitterVolume {

            performSegue(withIdentifier: "twitterSegue", sender: nil)
        }
    }

    /** load the chart data and then update the table cell
    - parameter cell: table cell to update
    - parameter data: Metric chart data to load
    */
    func loadChartData(_ cell: MetricCell, data: MetricAnomalyChartData) {

        loadQueue.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            data.load()
            if data.rawData != nil {
                DispatchQueue.main.async {

                    data.setEndDate(  (self.timeSlider?.endDate)!)
                    data.collapsed = self.marketHoursOnly
                    data.refreshData()
                    cell.chart.data  = data.rawData!
                    cell.chart.anomalies = data.data!
                    cell.chart.updateData()
                    cell.data = data

                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }

    /* load twitter scene
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "twitterSegue" {
            if let indexPath = self.instanceTable.indexPathForSelectedRow {
                let controller = segue.destination as! TwitterViewController

                controller.metricChartData = self.metricChartData[indexPath.row].shallowCopy()
                controller.chartData = self.chartData

                let cell = self.instanceTable.cellForRow(at: indexPath) as! MetricCell

                if cell.chart.selection != -1 {

                    if let data = controller.metricChartData?.anomalies {
                        if !data.isEmpty {
                            let firstBucket = data.count - TaurusApplication.getTotalBarsOnChart()
                            let selection = cell.chart.selection
                            var selectedBucket = firstBucket + selection/12
                            var value = data[selectedBucket]
                            let selectedTime = value.0 + Int64(selection % 12) * DataUtils.METRIC_DATA_INTERVAL

                            controller.timeToSelect = selectedTime

                            if self.marketHoursOnly {
                                // Find end of collapsed period to be expanded
                                while selectedBucket < data.count - 1 {
                                    if value.0 == 0 {
                                        selectedBucket -= 1
                                        value = data[selectedBucket]
                                        break
                                    }
                                    selectedBucket += 1
                                    value = data[selectedBucket]
                                }

                                // Check if selected collapsed bar
                                if value.0 == 0 {
                                    if selectedBucket > 0 {
                                        // Get previous bar instead
                                        selectedBucket -= 1
                                        value = data[selectedBucket]
                                    }
                                }

                                // Use end of period as end date (right most bar)
                                var timestamp = controller.chartData?.endDate
                                if value.0 != 0 {
                                    timestamp = value.0
                                }

                                controller.chartData?.setEndDate(DataUtils.dateFromTimestamp(timestamp!))
                            }
                        }
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        // Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "com.numenta.taurus.instance.InstanceDetailActivity")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker?.send(builder?.build() as! [AnyHashable: Any])
    }
}
