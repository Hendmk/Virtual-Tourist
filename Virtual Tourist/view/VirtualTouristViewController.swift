//
//  VirtualTouristViewController.swift
//  Virtual Tourist
//
//  Created by Hend Alkabani on 08/02/2019.
//  Copyright © 2019 Hend Alkabani. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Kingfisher

class VirtualTouristViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout  {
    
    var fetchedResultsController:NSFetchedResultsController<Pictures>!
    
    var pin = MKAnnotationView()
    var pictures: [Pictures] = []
    var dataController:DataController!
    var myPin: Pins!
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollec: UICollectionView!
    @IBOutlet weak var reloadPhoto: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(myPin.lat) + \(myPin.long)")
        if !reloadPic() {
            forcereloadPic()
        }
        showPins(lati: (pin.annotation?.coordinate.latitude)!, long: (pin.annotation?.coordinate.longitude)!)
    }
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.photoCollec.reloadData()
        }
    }
    

    
    @IBAction func reload(_ sender: Any) {
        forcereloadPic()
        setViewState("")
    }
    
    
    
    @objc func forcereloadPic() {
        DispatchQueue.main.async {
            self.setViewState("downloading")}
        networkCall()
    }
    
    func reloadPic() -> Bool {
        return loadSavedData()
    }
    
    func loadSavedData() -> Bool {
        
        if fetchedResultsController == nil {
            let fetchRequest:NSFetchRequest<Pictures> = Pictures.fetchRequest()
            let predicate = NSPredicate(format: "pins == %@", myPin)
            fetchRequest.predicate = predicate
            let sort = NSSortDescriptor(key: "creationDate", ascending: true)
            fetchRequest.sortDescriptors = [sort]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
        }
        
        do {
            try fetchedResultsController.performFetch()
            if (fetchedResultsController.fetchedObjects?.count)! > 0{
                return true
            }

        } catch {
            print("Fetch failed")
        }
        return false
    }

    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        if (fetchedResultsController.fetchedObjects?.count)! > 0 {
        let photo = fetchedResultsController.object(at: indexPath)
        let imageURL = URL(string: photo.imageUrl!)
            cell.photoCell.kf.indicatorType = .activity
            cell.photoCell.kf.setImage(with: imageURL)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let deletePhoto = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(deletePhoto)
        try? dataController.viewContext.save()
        loadSavedData()
        collectionView.reloadData()
    }
    
    
    func showPins(lati: Double, long: Double) {
        var annotations = [MKPointAnnotation]()
        let lat = CLLocationDegrees(lati)
        let long = CLLocationDegrees(long)
        
        let coordinate = CLLocationCoordinate2D(latitude: lat , longitude: long )
        
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotations.append(annotation)
        
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
        
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
    
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func networkCall() {
        networkConnection.getPictures(lat: "\(myPin.lat)", long: "\(myPin.long)", pin: myPin, dataController: dataController) { (errorMessage) in
            if errorMessage == nil{
                DispatchQueue.main.async {
                    self.setViewState("")
                    self.reloadPic()
                }
            }
            else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: errorMessage!)
                }
            }
        }
    }
    
    
    
    func setViewState(_ status: String) {
        switch status {
        case "downloading":
            indicatorView = self.startAnActivityIndicator()
            indicatorView.isHidden = false
            indicatorView.startAnimating()
            mapView.alpha = 0.5
            reloadPhoto.isEnabled = false
            break
            
        default:
            DispatchQueue.main.async {
                self.photoCollec.reloadData()
            }
            indicatorView.isHidden = true
            indicatorView.stopAnimating()
            mapView.alpha = 1.0
            reloadPhoto.isEnabled = true
            break
        }
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width-4
        //let spacificWidth = (width - (2*margin + internalSpacing * CGFloat(numberOfItems - 1)))/CGFloat(numberOfItems)
        return CGSize(width: width/3 , height: width/3)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0 , left: 1, bottom: 0, right: 1)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
}


extension UIViewController {
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension UIViewController {
    func startAnActivityIndicator() -> UIActivityIndicatorView {
        let ai = UIActivityIndicatorView(style: .gray)
        self.view.addSubview(ai)
        self.view.bringSubviewToFront(ai)
        ai.center = self.view.center
        ai.hidesWhenStopped = true
        ai.startAnimating()
        return ai
    }
}


