//
//  HeaderView.swift
//  CollectionViewCompositionalLayoutSample
//
//  Created by 岩本康孝 on 2022/10/15.
//  Copyright © 2022 Yasutaka Iwamoto. All rights reserved.
//

import UIKit

class HeaderView: UICollectionReusableView {

    @IBOutlet weak var headerText: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(text: String?) {
        headerText.text = text
    }
    
}
