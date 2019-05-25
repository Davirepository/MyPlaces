//
//  StorageManager.swift
//  MyPlaces
//
//  Created by Давид on 04/05/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import RealmSwift

let realm = try! Realm()

class StorageManager {
    
    // метод для добавления в базу
    static func saveObject(_ place: Place) {
        try! realm.write {
            realm.add(place)
        }
    }
    
    // удаление из базы
    static func deleteObject(_ place: Place) {
        try! realm.write {
            realm.delete(place)
        }
    }
}
