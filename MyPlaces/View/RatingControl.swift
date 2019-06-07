//
//  RatingControl.swift
//  MyPlaces
//
//  Created by Давид on 05/05/2019.
//  Copyright © 2019 Давид. All rights reserved.
//

import UIKit

 @IBDesignable class RatingControl: UIStackView { // @IBDesignable - позволяет отобразить создаваемы контент в интерфейсбилдер в реальном времени
    
    // MARK: ...Properties
    
    private var ratingButtons = [UIButton]()
    var rating = 0 {                // когда меняется рейтинг тогда закрашивается нужное кол-во звезд
        didSet {
            updateButtonSelectionState()
        }
    }
    
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {  // @IBInspectable - позволяет отобразить свойсва в инспекторе интерфейсбилдера
        didSet {                     
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }
    
    
    // MARK: ...Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    // MARK: ...Button Action
    
    @objc func ratingButtonTapped(button: UIButton) {
        
        guard let index = ratingButtons.firstIndex(of: button) else { return } 
        
        // Calculate the rating of the selected button
        let selectedRating = index + 1
        
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
    }
    
    // MARK: ...Private Methods
    
    private func setupButtons() {
        
         // так как у нас фиксированно создается 5 кнопок, то при увеличении их числа через испектор, кол-во будет прибавляться к уже имеющимся 5, поэтому сначала удаляем все кнопки, перед их новым созданием
        for button in ratingButtons {
            removeArrangedSubview(button)   // удаление кнопки из сабвью
            button.removeFromSuperview()    // удаление из стеквью
        }
        ratingButtons.removeAll()   // очищение массива кнопок
        
        // Load button image
        let bundle = Bundle(for: type(of: self))        // путь к assets
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection) // место хранения картинки
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        
        for _ in 0..<starCount {                    // создание 5 кнопок (для создания дистанции между копками выставляем спейсинг)
            // Create the button
            let button = UIButton()
            
            // Set the button image
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highlightedStar, for: .highlighted)
            button.setImage(highlightedStar, for: [.highlighted, .selected])
            
            // Add constraints
            button.translatesAutoresizingMaskIntoConstraints = false       // отключение автоматически сгенерированных констрейтов(в stackView он автоматически отключается)
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            button.widthAnchor.constraint(equalToConstant: starSize.width) .isActive = true
            
            // Setup the button action
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add the button to the stack
            addArrangedSubview(button)
            
            // Add the new button in the rating button array
            ratingButtons.append(button)
        }
        updateButtonSelectionState() // для отображения рейтинга по умолчания в интерфейсбилдере(в данном случае он ни на что не влияет)
    }
    
    // метод заполнения звезд
    private func updateButtonSelectionState() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }

}
