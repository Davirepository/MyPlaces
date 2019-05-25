//
//  MapManager.swift
//  MyPlaces
//
//  Created by Давид on 08/05/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import UIKit
import MapKit

class MapManager {
    
    // MARK: ...Properties
    
    let locationManager = CLLocationManager()     // настройка и управление службами геолокации
    
    private var placeCoordinate: CLLocationCoordinate2D? // хранение координат заведения
    private let regionInMeters = 1000.00
    private var directionsArray: [MKDirections] = []    //  массив маршрутов которые создает пользователь при движении
    
    // MARK: ...Methods
    
    // оставляем метку на карте(Маркер заведения)
    func setupPlacemark(place: Place, mapView: MKMapView) {
        
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder() // CLGeocoder() - преобразует географ координаты и названия в удобный для пользователя вид
        // преобразование адреса в координаты
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error, "Cant get addres line 101")
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            
            // описание точки на карте
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate     // получаем координаты заведения
            
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)   // выделение метки
        }
    }
    
    
    // проверка вкл службы геолокации
    func chekLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        
        if CLLocationManager.locationServicesEnabled() {        // доступность службы геолокации
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            // если отключили доступ к геолокации конкретно для этого приложения, то выйдет ошибка
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {                                               // если отключены глобальны сервисы определения геолокации, то выйдет ошибка
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {           // либо отложить задачу либо вызывать во viewdidapear(который вызывается уже после появления вью)
                self.showAlert(
                    title: "Loacation Services are Disabled",
                    message: "To enable it go: Settings -> Privacy -> Location Services and turn On"
                )
            }
        }
    }
    
    // Проверка авторизации приложения для исопользования сервисов геолокации
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:                         // приложению разрешено использовать геолокацию
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }  // центрируем карту на пользователе если переход был с поля локации
            break
        case .denied:                     // приложению отказано использовать службу геолокации
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                self.showAlert(title: "Your Location is not Availeble",
                               message: "To give permission Go to: Setting -> MyPlaces -> Location"
                )
            }
            break
        case .notDetermined:          // пользователь не решил использовать ли службу геолокации(опбычно при первом запуске)
            locationManager.requestWhenInUseAuthorization()   // вкл в plist (Privacy - Location When In Use Usage Description) для разрешения и пояснения
        case .restricted:       // приложение не авторизовано для использования служб геолокации
            break
        case .authorizedAlways:  // приложению разрешено использовать службы геолокации постоянно
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    // метод для цетрирования карты на местоположении пользователя
    func showUserLocation(mapView: MKMapView) {
        
        if let location = locationManager.location?.coordinate { //  определили координаты пользователя
            let region = MKCoordinateRegion(
                center: location,
                latitudinalMeters: regionInMeters,
                longitudinalMeters: regionInMeters
            )
            mapView.setRegion(region, animated: true)  // установка региона на экране
        }
    }
    
    // метод для прокладки маршрута от пользователя до заведения
    func getDirections(for mapView: MKMapView, travelInfo: UILabel, previousLocation: (CLLocation) -> ()) {
        
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "error", message: "Current location is not found")
            return
        }
        
        // постоянное обновление положения пользователя
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        // запрос на прокладку маршрута
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request)
        
        // удаление маршрутов
        resetMapView(withNew: directions, mapView: mapView)
        
        // создание нового маршрута
        // расчет маршрута
        directions.calculate { (response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Error", message: "Direction is no available")
                return
            }
            
            // работаем с каждым маршрутом в отдельности(каждый маршрут имее собственные данные о длительности и тд)
            for route in response.routes {
                // создаем дополнительное наложение на карту
                mapView.addOverlay(route.polyline)  // route.polyline - подробная геометрия всего маршрута
                // зона видимости карты взависимости от ее геометрии
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                // доп инфа по маршруту(расстояние и время)
                let distanse = String(format: "%1.f", route.distance / 1000) // перевод в метры
                let timeInterval = route.expectedTravelTime // в секундах
                
                travelInfo.text = "До места назначения осталось: \(distanse) км. \nВремя прибытия через: \(String(format: "%1.f", timeInterval / 3600)):\(String(format: "%1.f", timeInterval / 60)):\(String(format: "%1.f", timeInterval / 36))"
//                print("До места \(distanse) км")// можно сделать лейбл который нужно отображать после стройки маршрута
//                print(" Время \(timeInterval) с")
            }
        }
    }
    
    // Настройка запроса для расчета маршрута
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else { return nil }   // координаты для определения точки на карте
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation) // начальная точка маршрута
        request.destination = MKMapItem(placemark: destination) // местоположение конечной точки
        request.transportType = .automobile
        request.requestsAlternateRoutes = true // строит несколько маршрутов если есть альтернативные варианты
        
        return request
    }
    
    // обновление карты и ее перемещение при перемещении пользователя
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView)
        // перемещаем центр карты если новая и старая точки отличаются на 50 м
        guard center.distance(from: location) > 50 else { return }
        
        // передаем в клоужер центр отображаемой области
        closure(center)
    }
    
    
    // метод для отмены и удаления всех действующих маршрутов с карты
    // вызываем перед созданием нового маршрута
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        
        // удаление текущего маршрута
        mapView.removeOverlays(mapView.overlays)
        // добавление в массив текущие маршруты
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() } // отмена маршрутов
        directionsArray.removeAll()
    }
    
    // метод для определения центра координат(возвращение адреса)
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude // центр широты
        let longitude = mapView.centerCoordinate.longitude // цент долготы
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(ok)
        
        // так как class MapManager не имеет ничего общего с вьюконтроллерами
        // создаем объект UIWindow и инициализируем его свой-во rootViewController
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1 // определяем позиционирование(поверх других окон)
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true)
    }
    
    // MARK: ...Deinit
    //проверка выгрузки классов и контроллеров
    // проверка утечек памяти
    deinit {
        print("deinit", MapManager.self)
    }
}
