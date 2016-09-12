//
//  ViewController.swift
//  Trax
//
//  Created by enting chen on 2016/9/8.
//  Copyright © 2016年 enting chen. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {

    var gpxURL: NSURL? {
        didSet {
            
            clearWayPoints()
            
            if let url = gpxURL {
                GPX.parse(url) { gpx in
                    if gpx != nil {
                        self.addWayPoints(gpx!.waypoints)
                    }
                }
            }
        }
    }
    
    private func clearWayPoints() {
        mapView?.removeAnnotations(mapView.annotations)
    }
    
    private func addWayPoints(waypoints: [GPX.Waypoint]) {
        mapView?.addAnnotations(waypoints)
        mapView?.showAnnotations(waypoints, animated: true)
        
        
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        // set annotation to draggable
        view.draggable = annotation is EditableWaypoint
        
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            if waypoint is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            }
        }
        
        return view
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton,
            let url = (view.annotation as? GPX.Waypoint)?.thumbnailURL,
            let imageData = NSData(contentsOfURL: url), // blocks main queue
            let image = UIImage(data: imageData) {
            thumbnailImageButton.setImage(image, forState: .Normal)
        }
    }

    
    // MARK: Constants
    
    private struct Constants {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59) // sad face
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditUserWaypoint = "Edit Waypoint"
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
        }
        else if control == view.rightCalloutAccessoryView {
            
            // disappear annotation infomation when click right button
            mapView.deselectAnnotation(view.annotation, animated: true)
            
            performSegueWithIdentifier(Constants.EditUserWaypoint, sender: view )
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController.contentViewController
        let annotationView = sender as? MKAnnotationView
        let waypoint = annotationView?.annotation as? GPX.Waypoint
        
        if segue.identifier == Constants.ShowImageSegue {
            if let ivc = destination as? ImageViewController {
                ivc.imageURL = waypoint?.imageURL
                ivc.title = waypoint?.name
            }
        }else if segue.identifier == Constants.EditUserWaypoint {
            if let editableWaypoint = waypoint as? EditableWaypoint,
                let ewvc = destination as? EditWaypointViewController {
                if let ppc = ewvc.popoverPresentationController {
                    ppc.sourceRect = annotationView!.frame
                    ppc.delegate = self
                }
                ewvc.waypointToEdit = editableWaypoint
            }
        }

    }
    
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        selectWaypoint((popoverPresentationController.presentedViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    func presentationController(
        controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
        ) -> UIViewController? {
        if style == .FullScreen || style == .OverFullScreen {
            let navcon = UINavigationController(rootViewController: controller.presentedViewController)
            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
            visualEffectView.frame = navcon.view.bounds
            visualEffectView.autoresizingMask = [.FlexibleWidth,.FlexibleHeight]
            navcon.view.insertSubview(visualEffectView, atIndex: 0)
            return navcon
        } else {
            return nil
        }
    }
    
    func adaptivePresentationStyleForPresentationController(
        controller: UIPresentationController,
        traitCollection: UITraitCollection
        ) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .Compact ? .OverFullScreen : .None
    }
    
    @IBAction func addWaypoint(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .Began {
            let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
            //let waypoint = GPX.Waypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
            mapView.addAnnotation(waypoint)
        }
        
    }
    
    
    // Unwind target (selects just-edited waypoint)
    
    @IBAction func updatedUserWaypoint(segue: UIStoryboardSegue) {
        selectWaypoint((segue.sourceViewController.contentViewController as? EditWaypointViewController)?.waypointToEdit)
    }

    private func selectWaypoint(waypoint: GPX.Waypoint?) {
        if waypoint != nil {
            mapView.selectAnnotation(waypoint!, animated: true)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx")
        
    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            
            mapView.mapType = .Satellite
            //mapView.mapType = .Standard
            //mapView.showsUserLocation = true
            
            mapView.delegate = self
        }
    }

}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}


