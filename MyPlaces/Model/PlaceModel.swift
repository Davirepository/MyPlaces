//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Давид on 04/05/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import RealmSwift

class Place: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    @objc dynamic var date = Date()
    @objc dynamic var rating = 0.0
    
    convenience init(name: String, location: String?, type: String?, imageData: Data?, rating: Double) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
    
    
//    let restaurantNames = [
//            "Burger Heroes", "Kitchen", "Bonsai", "Дастархан",
//            "Индокитай", "X.O", "Балкан Гриль", "Sherlock Holmes",
//            "Speak Easy", "Morris Pub", "Вкусные истории",
//            "Классик", "Love&Life", "Шок", "Бочка"
//        ]
//
//    func savePlaces() {
//
//        for place in restaurantNames {
//
//            let image = UIImage(named: place)
//            guard let imageData = image?.pngData() else { return }
//
//            let newPlace = Place()
//
//            newPlace.name = place
//            newPlace.location = "Moscow"
//            newPlace.type = "Restaurant"
//            newPlace.imageData = imageData
//
//            StorageManager.saveObject(newPlace)
//        }
//    }
}
