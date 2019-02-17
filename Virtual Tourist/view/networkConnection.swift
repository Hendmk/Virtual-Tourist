//
//  networkConnection.swift
//  Virtual Tourist
//
//  Created by Hend Alkabani on 14/02/2019.
//  Copyright © 2019 Hend Alkabani. All rights reserved.
//
import UIKit
import Foundation

class networkConnection {
    static  func getPictures(lat: String, long: String, pin: Pins, dataController: DataController, completion: @escaping (String?)->Void) {
        // Generate random page to locad new set of data
        let randomePage = Int(arc4random_uniform(UInt32(10)))
        
        let request = URLRequest(url: URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=a6e4c665ca6192804f9085e9ac7e5729&lat=\(lat)&lon=\(long)&extras=url_m&per_page=12&page=\(randomePage)&format=json&nojsoncallback=1")!)
        
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // no error, woohoo!
            if error == nil {
                
                // there was data returned
                if let data = data {
                    
                    let parsedResult: [String:AnyObject]!
                    do {
                        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                    } catch {
                        completion("Could not parse the data as JSON: '\(data)'")
                        return
                    }
                    
                    //print(parsedResult)
                    
                    if let photosDictionary = parsedResult["photos"] as? [String:AnyObject], let photoArray = photosDictionary["photo"] as? [[String:AnyObject]] {
                        
                        pin.pictures = NSSet()
                        for i in 0..<photoArray.count {
                            let photosDictionary = photoArray[i] as [String:AnyObject]
                            if let imageUrlString = photosDictionary["url_m"] as? String {
                                //print(imageUrlString)
                                let photo = Pictures(context: dataController.viewContext)
                                photo.imageUrl = imageUrlString
                                photo.creationDate = Date()
                                pin.addToPictures(photo)
                                
                                let url = URL(string: imageUrlString)
                                let data = try? Data(contentsOf: url!)
                                let image = UIImage(data: data!)
                                let dataPhoto = image!.pngData() as Data?
                                photo.image = dataPhoto
                            }
                        }
                        try? dataController.viewContext.save()
                    }
                } else {
                    completion("No data was returned by the request!")
                }
            } else {
                completion("There was an error with your request")
            }
            completion(nil)
        }
        task.resume()
    }
}

