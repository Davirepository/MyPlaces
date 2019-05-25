//
//  NewPlaceViewController.swift
//  MyPlaces
//
//  Created by Давид on 04/05/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import UIKit

class NewPlaceViewController: UITableViewController {
    
    var currentPlace: Place!
    var imageIsChanged = false            // случай когда пользовательне добавляет картику к новому месту

    @IBOutlet weak var imageOfPlace: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeLocation: UITextField!
    @IBOutlet weak var placeType: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1)) // удаление разметки таблицы под контентом
        saveButton.isEnabled = false
        
        // добавление функционала для поля при его исправлении(вкл и откл кнопки сейв если поле не заполненно)
        placeName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        setupEditScreen()
        
    }
    
    // MARK: ...TableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let cameraIcon = #imageLiteral(resourceName: "camera")                      // image Litteral
            let photoIcon = #imageLiteral(resourceName: "photo")
            let actionSheet = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet
            )
            let camera = UIAlertAction(
                title: "Camera",
                style: .default) { (_) in
                    // не забываем добавлять просьбу о разрешении использовать камеру в plist через (NSCameraUsageDescription) и ключ для него ($(PRODUCT_NAME) photo use)
                    self.chooseImagePicker(source: .camera)
            }
            camera.setValue(cameraIcon, forKey: "image")        // установка изображения на кнопку
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment") // выравнивание текста кнопки по левому краю
            let photo = UIAlertAction(
                title: "Photo",
                style: .default) { (_) in
                    self.chooseImagePicker(source: .photoLibrary)
            }
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            let cancel = UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            )
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            present(actionSheet, animated: true, completion: nil)
        } else {
            view.endEditing(true)           // скрытие клавиатуры по тапу на другом поле
        }
    }
    
    // MARK: ...Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // так как есть два перехода на след экран
        // создаем переменную куда будем сохранять название перехода
        guard let identifier = segue.identifier,
            let mapVC = segue.destination as? MapViewController
            else { return }
        
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapViewControllerDelegate = self      // создаем делегат класса и подписываем его на протокол(делаем в отдельном расширении)
        
        if identifier == "showPlace" {
        // независимость от заполненных полей, благодаря чему можем проврять свою локацию без других полей
        mapVC.place.name = placeName.text!
        mapVC.place.location = placeLocation.text!
        mapVC.place.type = placeType.text!
        mapVC.place.imageData = imageOfPlace.image?.pngData()
        }
    }
    
    // MARK: ...Methods
    
    func savePlace() {
        // логика для добавленной и недобавленной картинки
        let image = imageIsChanged ? imageOfPlace.image : #imageLiteral(resourceName: "imagePlaceholder")
        let imageData = image?.pngData()
        
        let newPlace = Place(
            name: placeName.text!,
            location: placeLocation.text!,
            type: placeType.text!,
            imageData: imageData,
            rating: Double(ratingControl.rating)
        )
        if currentPlace != nil {
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            StorageManager.saveObject(newPlace)
        }
    }
    
    // функция для заполнения полей выбранной ячейки для редактирования
    private func setupEditScreen() {
        if currentPlace != nil {
            setupNavigationBar()
            imageIsChanged = true
            
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else { return }
            
            imageOfPlace.image = image
            imageOfPlace.contentMode = .scaleAspectFit      // масштабирование изображения
            placeName.text = currentPlace?.name
            placeLocation.text = currentPlace?.location
            placeType.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
        }
    }
    
    // метод редактирования навигейшн при редактировании записи
    private func setupNavigationBar() {
        // изменение кнопки назад
        if let topItem = navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(
                title: "",
                style: .plain,
                target: nil,
                action: nil
            )
        }
        // удаление кнопки отмена, редактирование заголовка и активация кнопки save
        navigationItem.leftBarButtonItem = nil
        title = currentPlace?.name
        saveButton.isEnabled = true
    }
    // MARK: ...@IBAction
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: ...Deinit
    //проверка выгрузки классов и контроллеров
    // проверка утечек памяти
    deinit {
        print("deinit", NewPlaceViewController.self)
    }
}


// MARK: ...TextFieldDelegate

extension NewPlaceViewController: UITextFieldDelegate {
    // скрытие клаиатуры по нажатию на кнопку Done
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // отслеживание поля на присутствие в нем значений
    @objc private func textFieldChanged() {
        
        if placeName.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
}

// MARK: ...Work with Image
extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self // делегирует обязанности по выполнению метода imagePickerController нашему классу
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        imageOfPlace.image = info[.editedImage] as? UIImage // использование отредактированного пользователем изображение
        imageOfPlace.contentMode = .scaleAspectFit      // масштабирование изобраение по image
        imageOfPlace.clipsToBounds = true
        
        imageIsChanged = true                           // если мы поменяли картику то все ок
        
        dismiss(animated: true)        //закрытие
    }
}

extension NewPlaceViewController: MapViewControllerDelegate {
    
    func getAddress(_ address: String?) {  // параметр метода, address, уже содержит значение выбранного адреса
        placeLocation.text = address
    }
}
