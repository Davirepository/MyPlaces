//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Давид on 02/05/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    private let searchController = UISearchController(searchResultsController: nil)
    private var places: Results<Place>!         // объект для записи и считывания
    private var filteredPlaces: Results<Place>!  // отфильтрованный массив для поиска
    private var ascendingSorting = true         // сортировка по возрастанию
    private var searchBarIsEmplty: Bool {       // проверка строки поиска на пустоту
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {                             // активация поисковых запросов
        return searchController.isActive && !searchBarIsEmplty  // true если актированна и не пустая
    }
    
    // MARK: - @IBOutlet
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingButton: UIBarButtonItem!
    
    
    // MARK: - viewDidLoad() Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // отбражение данных на экране(запрос к базе данных realm)
        places = realm.objects(Place.self)
        
        //Setup the search controller
        searchController.searchResultsUpdater = self    // получателем информации о изменении текста в поисковой строке - наш класс
        searchController.obscuresBackgroundDuringPresentation = false       // оключение блокировки экрана при поиске(получаем возможность сразу выбрат то, что нам было предложено)
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true                   // отпускаем строку поиска при переходе на другой экран
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {                    // если фильтруем через поиск, то возвращаем кол-во подходящих ответов
            return filteredPlaces.count
        }
        return places.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
        // возвращаем либо массив имеющихся данных либо отфильтрованный, через поисковую строку если она использовалась
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        cell.cosmosView.rating = place.rating
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let place = places[indexPath.row]
        // удаление из базы и таблицы
        let deleteAction = UITableViewRowAction(
            style: .default,
            title: "Delete") { (_, _) in
                StorageManager.deleteObject(place)
                tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        return [deleteAction]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail" else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        // передаем либо массив имеющихся данных либо отфильтрованный, через поисковую строку если она использовалась
        // иначе отфильтрованный массив будет передавать 1 строку неотфильтрованного массива
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        let newPlaceVC = segue.destination as! NewPlaceViewController
        newPlaceVC.currentPlace = place
    }
    
    // MARK: - @IBAction
    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        
        guard let newPlaceVC = segue.source as? NewPlaceViewController else { return }
        newPlaceVC.savePlace()
        //        places.append(newPlaceVC.newPlace!)
        tableView.reloadData()
    }
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        sorting()
    }
    
    @IBAction func reversedSorting(_ sender: Any) {
        ascendingSorting.toggle()
        
        if ascendingSorting {
            reversedSortingButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedSortingButton.image = #imageLiteral(resourceName: "ZA")
        }
        
        sorting()
    }
    
    // MARK: - Methods
    
    private func sorting() {
        if segmentedControl.selectedSegmentIndex == 0 {
            // сортировка по дате и/или в обратном порядке
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
        } else {
            // сортировка по имени и/или в обратном порядке
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
        }
        tableView.reloadData()
    }
    // MARK: ...Deinit
    //проверка выгрузки классов и контроллеров
    // проверка утечек памяти
    deinit {
        print("deinit", MainViewController.self)
    }
}


extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {    // вызывается когда тапаем по поисково строке
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    // метод фильтрации контента через поиск
    private func filterContentForSearchText(_ searchText: String) {
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)  // фильтрация через поисковую строку по name и location независимо от регистра символов
        tableView.reloadData()
    }
}
