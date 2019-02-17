//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Hend Alkabani on 07/02/2019.
//  Copyright © 2019 Hend Alkabani. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var pins: [Pins] = []
    var pin = MKAnnotationView()
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pins>!
    
    var coordanation = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        showPins()
        //deletePins()
    }
    
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pins> = Pins.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            pins = result
            var i = 0
            for s in pins {
                print("\(i) : \(s.lat)")
                print("\(i) : \(s.long)")
                i = i+1
            }
        }
    }
    
    
    @IBAction func addPins(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .ended {
            print("Long press Ended")
        } else if sender.state == .began {
            print("Long press detected")
            let location = sender.location(in: self.mapView)
            let locCoord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = locCoord
            
            self.mapView.addAnnotation(annotation)
            savePin(lat: locCoord.latitude, long: locCoord.longitude)
        }
    }
    
    func savePin(lat: Double, long: Double) {
        let addPin = Pins(context: dataController.viewContext)
        addPin.lat = lat
        addPin.long = long
        try? dataController.viewContext.save()
        pins.append(addPin)
        
        setupFetchedResultsController()
    }
    
    func showPins() {
        guard pins.count > 0 else { return }
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            let lat = CLLocationDegrees(pin.lat)
            let long = CLLocationDegrees(pin.long)
            
            let coordinate = CLLocationCoordinate2D(latitude: lat , longitude: long )
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var myPin: Pins!
        
        let fetchRequest: NSFetchRequest<Pins> = Pins.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lat = \(view.annotation?.coordinate.latitude ?? 0.0) AND long = \(view.annotation?.coordinate.longitude ?? 0.0)")
        if let results = try? dataController.viewContext.fetch(fetchRequest) {
            if results.count <= 0 {
                // No object found
            }
            myPin = results[0]
        }
        
        
        let vc  = storyboard!.instantiateViewController(withIdentifier: "vt") as! VirtualTouristViewController
        vc.pin = view
        vc.myPin = myPin
        vc.dataController = dataController
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    func deletePins() {
        for s in pins{
        dataController.viewContext.delete(s)
    }
        try? dataController.viewContext.save()
        
    }
    
}

