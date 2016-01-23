//
//  CarbEntryTableViewController.swift
//  CarbKit
//
//  Created by Nathan Racklyeft on 1/10/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import UIKit

private let ReuseIdentifier = "CarbEntry"

public class CarbEntryTableViewController: UITableViewController {

    @IBOutlet var unavailableMessageView: UIView!

    @IBOutlet var authorizationRequiredMessageView: UIView!

    @IBOutlet weak var COBValueLabel: UILabel!

    @IBOutlet weak var COBDateLabel: UILabel!

    @IBOutlet weak var totalValueLabel: UILabel!

    @IBOutlet weak var totalDateLabel: UILabel!

    public var carbStore: CarbStore?

    private var updateTimer: NSTimer? {
        willSet {
            if let timer = updateTimer {
                timer.invalidate()
            }
        }
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if let carbStore = carbStore {
            if carbStore.authorizationRequired {
                state = .AuthorizationRequired(carbStore)
            } else {
                state = .Display(carbStore)
            }
        } else {
            state = .Unavailable
        }

        navigationItem.leftBarButtonItem = editButtonItem()
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        updateTimelyStats(nil)
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let updateInterval = NSTimeInterval(minutes: 5)
        let timer = NSTimer(
            fireDate: NSDate().dateCeiledToTimeInterval(updateInterval).dateByAddingTimeInterval(2),
            interval: updateInterval,
            target: self,
            selector: "updateTimelyStats:",
            userInfo: nil,
            repeats: true
        )
        updateTimer = timer

        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        updateTimer = nil
    }

    deinit {
        carbStoreObserver = nil
    }

    // MARK: - Data

    private var carbEntries: [CarbEntry] = []

    private enum State {
        case Unknown
        case Unavailable
        case AuthorizationRequired(CarbStore)
        case Display(CarbStore)
    }

    private var state = State.Unknown {
        didSet {
            switch state {
            case .Unknown:
                break
            case .Unavailable:
                tableView.backgroundView = unavailableMessageView
            case .AuthorizationRequired:
                tableView.backgroundView = authorizationRequiredMessageView
                carbStoreObserver = nil
            case .Display(let carbStore):
                carbStoreObserver = NSNotificationCenter.defaultCenter().addObserverForName(nil, object: carbStore, queue: NSOperationQueue.mainQueue(), usingBlock: { [unowned self] (note) -> Void in

                    self.reloadData()
                })

                navigationItem.leftBarButtonItem?.enabled = true
                navigationItem.rightBarButtonItem?.enabled = true

                tableView.backgroundView = nil
                tableView.tableHeaderView?.hidden = false
                tableView.tableFooterView = nil
                reloadData()
            }
        }
    }

    private func reloadData() {
        if case .Display(let carbStore) = state {
            carbStore.getRecentCarbEntries { (entries, error) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if let error = error {
                        self.presentAlertControllerWithError(error)
                    } else {
                        self.carbEntries = entries
                        self.tableView.reloadData()
                    }
                }

                self.updateTimelyStats(nil)
                self.updateTotal()
            }
        }
    }

    func updateTimelyStats(_: NSTimer?) {
        updateCOB()
    }

    private func updateCOB() {
        if case .Display(let carbStore) = state {
            carbStore.carbsOnBoardAtDate(NSDate(), resultHandler: { (value) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if let value = value {
                        self.COBValueLabel.text = NSNumberFormatter.localizedStringFromNumber(value.value, numberStyle: .NoStyle)
                        self.COBDateLabel.text = String(format: NSLocalizedString("com.loudnate.CarbKit.COBDateLabel", tableName: "CarbKit", value: "at %1$@", comment: "The format string describing the date of a COB value. The first format argument is the localized date."), NSDateFormatter.localizedStringFromDate(value.startDate, dateStyle: .NoStyle, timeStyle: .ShortStyle))
                    } else {
                        self.COBValueLabel.text = NSNumberFormatter.localizedStringFromNumber(0, numberStyle: .NoStyle)
                        self.COBDateLabel.text = nil
                    }
                }
            })
        }
    }

    private func updateTotal() {
        if case .Display(let carbStore) = state {
            carbStore.getTotalRecentCarbValue { (value) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if let value = value {
                        self.totalValueLabel.text = NSNumberFormatter.localizedStringFromNumber(value.value, numberStyle: .NoStyle)
                        self.totalDateLabel.text = String(format: NSLocalizedString("com.loudnate.CarbKit.totalDateLabel", tableName: "CarbKit", value: "since %1$@", comment: "The format string describing the starting date of a total value. The first format argument is the localized date."), NSDateFormatter.localizedStringFromDate(value.startDate, dateStyle: .NoStyle, timeStyle: .ShortStyle))
                    } else {
                        self.totalValueLabel.text = NSNumberFormatter.localizedStringFromNumber(0, numberStyle: .NoStyle)
                        self.totalDateLabel.text = nil
                    }
                }
            }
        }
    }

    private var carbStoreObserver: AnyObject? {
        willSet {
            if let observer = carbStoreObserver {
                NSNotificationCenter.defaultCenter().removeObserver(observer)
            }
        }
    }

    // MARK: - Table view data source

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch state {
        case .Unknown, .Unavailable, .AuthorizationRequired:
            return 0
        case .Display:
            return 1
        }
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return carbEntries.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ReuseIdentifier, forIndexPath: indexPath)

        let entry = carbEntries[indexPath.row]
        let value = NSNumberFormatter.localizedStringFromNumber(entry.value, numberStyle: .NoStyle)

        var titleText = "\(value) g"

        if let foodType = entry.foodType {
            titleText += ": \(foodType)"
        }

        cell.textLabel?.text = titleText

        var detailText = NSDateFormatter.localizedStringFromDate(entry.startDate, dateStyle: .NoStyle, timeStyle: .ShortStyle)

        if let absorptionTime = entry.absorptionTime {
            let minutes = NSNumberFormatter.localizedStringFromNumber(absorptionTime.minutes, numberStyle: .NoStyle)
            detailText += " + \(minutes) min"
        }

        cell.detailTextLabel?.text = detailText

        return cell
    }

    override public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return carbEntries[indexPath.row].createdByCurrentApp
    }

    override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let entry = carbEntries.removeAtIndex(indexPath.row)
            carbStore?.deleteCarbEntry(entry, resultHandler: { (success, error) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if success {
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    } else if let error = error {
                        self.presentAlertControllerWithError(error)
                    }
                }
            })
        }
    }

    // MARK: - UITableViewDelegate

    override public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let entry = carbEntries[indexPath.row]

        if !entry.createdByCurrentApp {
            return nil
        }

        return indexPath
    }

    // MARK: - Navigation

    @IBAction func unwindFromEditing(segue: UIStoryboardSegue) {
        if let  editVC = segue.sourceViewController as? CarbEntryEditViewController,
                updatedEntry = editVC.updatedCarbEntry
        {
            if let originalEntry = editVC.originalCarbEntry {
                carbStore?.replaceCarbEntry(originalEntry, withEntry: updatedEntry) { (_, _, error) -> Void in
                    if let error = error {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.presentAlertControllerWithError(error)
                        }
                    }
                }
            } else {
                carbStore?.addCarbEntry(updatedEntry) { (_, _, error) -> Void in
                    if let error = error {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.presentAlertControllerWithError(error)
                        }
                    }
                }
            }
        }
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var editVC = segue.destinationViewController as? CarbEntryEditViewController

        if editVC == nil, let navVC = segue.destinationViewController as? UINavigationController {
            editVC = navVC.viewControllers.first as? CarbEntryEditViewController
        }

        if let editVC = editVC {
            if let selectedCell = sender as? UITableViewCell, indexPath = tableView.indexPathForCell(selectedCell) where indexPath.row < carbEntries.count {
                editVC.originalCarbEntry = carbEntries[indexPath.row]
            }

            editVC.defaultAbsorptionTimes = carbStore?.defaultAbsorptionTimes ?? []
        }
    }

    @IBAction func authorizeHealth(sender: AnyObject) {
        if case .AuthorizationRequired(let carbStore) = state {
            carbStore.authorize { (success, error) in
                dispatch_async(dispatch_get_main_queue()) {
                    if success {
                        self.state = .Display(carbStore)
                    } else if let error = error {
                        self.presentAlertControllerWithError(error)
                    }
                }
            }
        }
    }

}