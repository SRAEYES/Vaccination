//
//  ViewController.swift
//  Vaccination
//
//  Created by user66 on 10/12/25.
//

import UIKit

class ViewController: UIViewController , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var filtersCollectionView: UICollectionView!
    @IBOutlet weak var vaccinesTableView: UITableView!
    @IBOutlet weak var bottomBar: UIView!



    let filterOptions = ["All", "At Birth", "6 Weeks", "10 Weeks", "14 Weeks", "6 Months", "9 Months", "12 Months", "18 Months", "5 Years", "10 Years", "14 Years"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // table setup
            vaccinesTableView.backgroundColor = .clear
            vaccinesTableView.separatorStyle = .none
            vaccinesTableView.estimatedRowHeight = 88
            vaccinesTableView.rowHeight = UITableView.automaticDimension

            // Add bottom content inset equal to bottomBar height + extra
            let bottomInset: CGFloat = bottomBar.bounds.height + 24
            vaccinesTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
            vaccinesTableView.scrollIndicatorInsets = vaccinesTableView.contentInset
        
        
//        styleBottomBar()
        setupFiltersCollectionView()
        setupVaccinesTableView()
    }

    private func setupFiltersCollectionView() {
           let nib = UINib(nibName: "AgeFilterCell", bundle: nil)
           filtersCollectionView.register(nib, forCellWithReuseIdentifier: "AgeFilterCell")
           filtersCollectionView.showsHorizontalScrollIndicator = false
       }
    private func setupVaccinesTableView() {
        vaccinesTableView.delegate = self
        vaccinesTableView.dataSource = self
        
        let nib = UINib(nibName: "VaccineCell", bundle: nil)
        vaccinesTableView.register(nib, forCellReuseIdentifier: "VaccineCell")
        
        vaccinesTableView.separatorStyle = .none
    }
    
    struct VaccineItem {
        let name: String
        let subtitle: String
    }

    
    let upcomingVaccines: [VaccineItem] = [
        VaccineItem(name: "Tuberculosis", subtitle: "Due in 5 days"),
        VaccineItem(name: "Poliomyelitis", subtitle: "Due in 25 days"),
        VaccineItem(name: "Hepatitis B", subtitle: "Due in 5 months")
    ]

    let completedVaccines: [VaccineItem] = [
        VaccineItem(name: "Rotavirus", subtitle: "Completed")
    ]

    var selectedFilterIndex: Int = 0

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilterIndex = indexPath.item
        collectionView.reloadData()
        // apply filter logic
    }

    // Number of items
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            print("numberOfItemsInSection called, count =", filterOptions.count)
            return filterOptions.count
        }
        
        // Cell for item
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AgeFilterCell", for: indexPath) as? AgeFilterCell else {
                return UICollectionViewCell()
            }
            
            let title = filterOptions[indexPath.item]
            let isSelected = (indexPath.item == 0) // For now, make "All" look selected
            
            cell.configure(with: title, isSelected: isSelected)
            print("cellForItemAt for index", indexPath.item)
            return cell
        }
        
        // Size for item (auto width based on text)
        func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {
            
//            let title = filterOptions[indexPath.item]
//            let font = UIFont.systemFont(ofSize: 14)
//            let textWidth = (title as NSString).size(withAttributes: [.font: font]).width
//            
//            return CGSize(width: textWidth + 24, height: 36)
            return CGSize(width: 80, height: 32)
        }
    
    func numberOfSections(in tableView: UITableView) -> Int {
            return 2 // Upcoming & Completed
        }

        func tableView(_ tableView: UITableView,
                       numberOfRowsInSection section: Int) -> Int {
            return section == 0 ? upcomingVaccines.count : completedVaccines.count
        }

        func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "VaccineCell",
                for: indexPath
            ) as? VaccineCell else {
                return UITableViewCell()
            }

            let item = indexPath.section == 0
                ? upcomingVaccines[indexPath.row]
                : completedVaccines[indexPath.row]

            cell.configure(name: item.name, subtitle: item.subtitle)
            cell.selectionStyle = .none
            return cell
        }

        // Optional: section headers (Upcoming / Completed)
        func tableView(_ tableView: UITableView,
                       titleForHeaderInSection section: Int) -> String? {
            return section == 0 ? "Upcoming" : "Completed"
        }

        // Optional: row height
        func tableView(_ tableView: UITableView,
                       heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80 // adjust for your design
        }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        styleBottomBar()
    }

    private func styleBottomBar() {
        // Make it a pill
        bottomBar.layer.cornerRadius = bottomBar.bounds.height / 2
        bottomBar.layer.masksToBounds = false  // important for shadow
        
        // Soft shadow for floating effect
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.15
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: 10)
        bottomBar.layer.shadowRadius = 20
        
        // Make sure inner blur view is clipped to the rounded shape
        if let blurView = bottomBar.subviews.first as? UIVisualEffectView {
            blurView.layer.cornerRadius = bottomBar.bounds.height / 2
            blurView.clipsToBounds = true
        }
//    }
//    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        if let header = view as? UITableViewHeaderFooterView {
//            header.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
//            header.textLabel?.textColor = UIColor.secondaryLabel
//            header.contentView.backgroundColor = .clear
//        }
//    }

    // If you want bigger spacing above section header, implement viewForHeaderInSection and return a custom view with top padding.
    
//    private func styleBottomBar() {
//        bottomBar.layer.cornerRadius = bottomBar.bounds.height / 2
//        bottomBar.layer.masksToBounds = false
//        bottomBar.layer.shadowColor = UIColor.black.cgColor
//        bottomBar.layer.shadowOpacity = 0.12
//        bottomBar.layer.shadowOffset = CGSize(width: 0, height: 8)
//        bottomBar.layer.shadowRadius = 18
//
//        // ensure blur clipped
//        if let blurView = bottomBar.subviews.compactMap({ $0 as? UIVisualEffectView }).first {
//            blurView.layer.cornerRadius = bottomBar.bounds.height / 2
//            blurView.clipsToBounds = true
//            blurView.contentView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
//        }
//
//        // add subtle inner highlight (optional)
//        let highlight = CAGradientLayer()
//        highlight.frame = bottomBar.bounds
//        highlight.colors = [UIColor.white.withAlphaComponent(0.06).cgColor, UIColor.clear.cgColor]
//        highlight.startPoint = CGPoint(x: 0.5, y: 0)
//        highlight.endPoint = CGPoint(x: 0.5, y: 1)
//        highlight.cornerRadius = bottomBar.bounds.height / 2
//        bottomBar.layer.insertSublayer(highlight, at: 0)
    }


}

