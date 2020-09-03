//
//  ViewController.swift
//  CollectionViewCompositionalLayoutSample
//
//  Created by yaiwamoto on 03/09/2020.
//  Copyright © 2020 Yasutaka Iwamoto. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        // Do any additional setup after loading the view.
    }
       
    private enum List: Int, CaseIterable {
        case list
        case grid
        case twoColumn
        
        var title: String {
            switch self {
            case .list:      return "List"
            case .grid:      return "Grid"
            case .twoColumn: return "TwoColumn"
            }
        }
    }

}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return List.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = List.allCases[indexPath.row].title
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = List.init(rawValue: indexPath.row)
        switch cell {
        case .list:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "ListViewController")
            navigationController?.pushViewController(vc, animated: true)
        case .grid:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "GridViewController")
            navigationController?.pushViewController(vc, animated: true)
        case .twoColumn:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "TwoColumnViewController")
            navigationController?.pushViewController(vc, animated: true)
        case .none:
            return
        }
    }
}
