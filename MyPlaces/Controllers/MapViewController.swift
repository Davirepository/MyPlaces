//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Давид on 06/05/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation // фреймворк для определения положения пользователя

// можно сделать необязательным к выполнению пометив методы и функцию @objc optional
protocol MapViewControllerDelegate {        // для передачи данных(сохранение выбранного адреса) в другой контроллер
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    // MARK: ...Properties
    
    let mapManager = MapManager()
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIdentifier = "annotationIdentifier"
    var incomeSegueIdentifier = ""     // св-во для отслеживания перехода и центрирования карты либо на заведении либо на пользователе
    
    
    var previousLocation: CLLocation? {
        didSet {
            mapManager.startTrackingUserLocation(
                for: mapView,
                and: previousLocation) {
                    (currentLocation) in // содержит координаты центра отображаемой области
                    
                    // передаем в previousLocation координаты центра отображаемой области
                    self.previousLocation = currentLocation
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.mapManager.showUserLocation(mapView: self.mapView)
                    }
            }
        }
    }

    // MARK: ...@IBOutlet
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!        // всегда в центре
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var travelInfo: UILabel!
    
    // MARK: ...viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = ""
        travelInfo.text = ""
        mapView.delegate = self
        setupMapView()
    }
    
    // MARK: ...@IBAction
    @IBAction func closeVC() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func centerViewInUserLocation() {
        // центрируем карту на пользователе
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func goButtonPressed() {
        mapManager.getDirections(for: mapView, travelInfo: travelInfo) {
            // координаты текущего местоположения пользователя
            (location) in
            self.previousLocation = location
        }
    }
    
    // при выборе адреса передаем данные в текстфил(location) другого контроллера
    // и переходим на него dismiss(animated: true)
    @IBAction func doneButtonPressed() { // передача данных через протокол
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
    
    // MARK: ...Methods
    
    // метод для центрирование карты на месте заведения и скрытия других кнопок
    // если переход был по картинки заведения
    private func setupMapView() {
        
        goButton.isHidden = true
        travelInfo.isHidden = true
        
        mapManager.chekLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showPlace" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
            travelInfo.isHidden = false
        }
    }
    
    // MARK: ...Deinit
    //проверка выгрузки классов и контроллеров
    // проверка утечек памяти
    deinit {
        print("deinit", MapViewController.self)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    // метод отвечающий за отображение аннотации
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        guard !(annotation is MKUserLocation) else { return nil }       // убеждаемся что это не текущее положение пользователя
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView // представление вью с анотацией на карте
        
        if annotationView == nil {      // если на карте нет аннотации
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
        
    }
    
    // отображается каждый раз при смене региона
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        // фокусировка центра карты на местоположении пользователя через t если мы ее двигаем
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        // для освобождения ресурсов связанных с геокодированием делаем отмену отложенного запроса
        geocoder.cancelGeocode()
        
        // преобразуем координаты в адрес
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
            
        }
    }
    
    // подсветка построенного маршрута
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)  //рендерим наложенное изображеное
        renderer.strokeColor = .blue    // красим
        
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate{
    
    // отслеживания обновления статуса(разрешение использования карты) в реальном времени
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        mapManager.checkLocationAuthorization(mapView: mapView,
                                              segueIdentifier: incomeSegueIdentifier
        )
    }
    
}
