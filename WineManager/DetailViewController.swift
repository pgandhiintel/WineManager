//
//  DetailViewController.swift
//  WineManager
//
//  Created by Prashant Gandhi (Intel) on 5/29/16.
//  Copyright © 2016 Prashant Gandhi. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, SavingDrunkViewControllerDelegate, EditLocationsViewControllerDelegate  {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var lotsLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var drunkLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var reviewView: UITextView!
    @IBOutlet weak var drunkHistoryLabel: UILabel!
    @IBOutlet weak var locationHistoryLabel: UILabel!

    @IBOutlet weak var drunkHistoryWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var drunkLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var drunkHistorySpacingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var locationHistoryWidthContraint: NSLayoutConstraint!
    @IBOutlet weak var locationLabelWidthContraint: NSLayoutConstraint!
    @IBOutlet weak var locationHistorySpacingConstraint: NSLayoutConstraint!


    @IBOutlet weak var markDrunkButton: UIBarButtonItem!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var bottleName = ""
    var bottleVintage = 0
    
    var detailItem: AnyObject? {
        didSet {
            //Update the view.
            //self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var lotDescription = ""
        var drunkDescription = ""
        var locDescription = ""
        var drunkBottles = 0
        var availBottles = 0
        
        var drunkArray : [(date: NSDate, rating: Double)] = []
        
        let fetchRequest = NSFetchRequest(entityName: "Bottle")
        let predicateVintage = NSPredicate(format: "vintage == %d", bottleVintage)
        let predicateName = NSPredicate(format: "name == %@", bottleName)
        let predicateCompound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateName, predicateVintage])
        fetchRequest.predicate = predicateCompound
        
        do {
            if let context = self.managedObjectContext {
                let fetchedEntities = try self.managedObjectContext!.executeFetchRequest(fetchRequest) as! [Bottle]
                NSLog("Found bottles " + String(fetchedEntities.count))
            
        
                if let bottle = fetchedEntities.first {
                    let bottleDetails = bottle //as! Bottle
                    if (bottleDetails.vintage! == 0) {
                        nameLabel.text = "NV " + bottleDetails.name!
                    } else {
                        nameLabel!.text = String(bottleDetails.vintage!) + " " + bottleDetails.name!
                    }
                    regionLabel!.text = bottleDetails.varietal! + " from " + bottleDetails.region! + ", " + bottleDetails.country!
                    let totalLots = bottleDetails.lots!.count
                    lotsLabel.numberOfLines = totalLots
                    
                    let sorter = NSSortDescriptor(key: "purchaseDate", ascending: false)
                    let sorted = bottleDetails.lots!.sortedArrayUsingDescriptors([sorter])
                    for (index, value) in sorted.enumerate() {//    for (index, value) in bottleDetails.lots!.enumerate() {
                        let lot = value as! PurchaseLot
                        if (lot.quantity == 1) {
                            lotDescription = lotDescription + lot.quantity!.stringValue + " bottle on " + dateFormatter.stringFromDate(lot.purchaseDate!) + " for $" + lot.price!.stringValue + "\n"
                        } else {
                            lotDescription = lotDescription + lot.quantity!.stringValue + " bottles on " + dateFormatter.stringFromDate(lot.purchaseDate!) + " for $" + lot.price!.stringValue + " each\n"
                        }
                        if (index == totalLots - 1) {
                            lotDescription = lotDescription.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
                        }
                    
                        for (_, value) in lot.statuses!.enumerate() {
                            let loc = value as! Status
                            if (loc.available == 0) {
                                drunkBottles += 1
                                drunkArray.append((date: loc.drunkDate!, rating: loc.rating!.doubleValue))
                                if (drunkDescription.isEmpty) {
                                    drunkDescription = loc.rating!.stringValue + " stars on " + dateFormatter.stringFromDate(loc.drunkDate!)
                                } else {
                                    drunkDescription = drunkDescription + "\n" + loc.rating!.stringValue + " stars on " + dateFormatter.stringFromDate(loc.drunkDate!)
                                }
                            } else {
                                availBottles += 1
                                if (locDescription.isEmpty) {
                                    locDescription = loc.location!
                                } else {
                                    locDescription = locDescription + ", " + loc.location!
                                }
                            }
                        }
                    }
                    lotsLabel!.text = lotDescription

                    drunkArray.sortInPlace {
                        return $0.date.compare($1.date) == NSComparisonResult.OrderedDescending
                    }
                    drunkDescription = ""
                    for (_, value) in drunkArray.enumerate() {
                        if (drunkDescription.isEmpty) {
                            drunkDescription = String(value.rating) + " stars on " + dateFormatter.stringFromDate(value.date)
                        } else {
                            drunkDescription = drunkDescription + "\n" + String(value.rating) + " stars on " + dateFormatter.stringFromDate(value.date)
                        }
                    }
                    
                    if (drunkDescription.isEmpty) {
                        drunkLabelWidthConstraint.constant = 0.0
                        drunkHistoryWidthConstraint.constant = 0.0
                        drunkHistorySpacingConstraint.constant = 0.0
                    } else {
                        drunkLabelWidthConstraint.constant = 21.0 * CGFloat(drunkBottles)
                        drunkHistoryWidthConstraint.constant = 21.0
                        drunkHistorySpacingConstraint.constant = 10.0
                        drunkLabel.numberOfLines = drunkBottles
                        drunkLabel!.text = drunkDescription
                    }
                    
                    if (locDescription.isEmpty) {
                        locationLabelWidthContraint.constant = 0.0
                        locationHistoryWidthContraint.constant = 0.0
                        locationHistorySpacingConstraint.constant = 0.0
                        markDrunkButton.enabled = false
                    } else {
                        locationLabel.numberOfLines = availBottles
                        locationLabel!.text = locDescription
                    }

                    ratingLabel!.text = bottleDetails.points!.stringValue + " pts by " + bottleDetails.reviewSource!
                    reviewView!.text = bottleDetails.review!
                }
            }
        }
        catch {
            abort()
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        (self.parentViewController as! UINavigationController).setToolbarHidden(false, animated: true)
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let viewSize: CGRect = reviewView.bounds
        let screenHeightNeeded = viewSize.height + CGFloat(200.0)
        scrollView.contentSize = CGSize(width: screenSize.width, height: screenHeightNeeded)
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMarkDrunk" {
            let controller = segue.destinationViewController as! MarkDrunkViewController
            let bottle = detailItem as! Bottle
            controller.bottleName = bottle.name!
            //var locations: [String] = []
            var locations = Set<String>()
            for (_, value) in bottle.lots!.enumerate() {
                let lot = value as! PurchaseLot
                for (_, value) in lot.statuses!.enumerate() {
                    let loc = value as! Status
                    if (loc.available == 1) {
                        locations.insert(loc.location!)
                    }
                }
            }
            controller.bottleLocations = locations
            controller.delegate = self
        }
        if segue.identifier == "showEditDetails" {
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! AddEditViewController
            controller.bottleInfo = self.detailItem
            controller.viewMode = "Edit"
            controller.managedObjectContext = self.managedObjectContext
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.delegate = self
        }
    }
    
    func applyLocationChanges(dataChanged: Bool) {
        if (dataChanged) {
            self.configureView()
        }
    }
    
    func saveDrunkInfo(rating: Float, date: NSDate, location: String) {
        var flagDone = false
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let bottle = detailItem as! Bottle
        for (_, value) in bottle.lots!.enumerate() {
            let lot = value as! PurchaseLot
            for (_, value) in lot.statuses!.enumerate() {
                let loc = value as! Status
                if (loc.available! == 1 && loc.location! == location && !flagDone) {
                    loc.available = 0
                    loc.location = ""
                    loc.drunkDate! = date
                    loc.rating! = NSDecimalNumber(float: rating)
                    lot.availableBottles = (lot.availableBottles?.integerValue)! - 1
                    lot.drunkBottles = (lot.drunkBottles?.integerValue)! + 1
                    bottle.availableBottles! = (bottle.availableBottles?.integerValue)! - 1
                    bottle.drunkBottles! = (bottle.drunkBottles?.integerValue)! + 1
                    bottle.lastDrunkDate! = date
                    flagDone = true
                    break
                }
            }
        }
        do {
            try bottle.managedObjectContext?.save()
            detailItem = bottle
            self.configureView()
        } catch {
            let saveError = error as NSError
            NSLog(String(saveError))
        }
        
    }

}

