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
    @IBOutlet weak var advancedFilterButton: UIButton!   // connect this to the small icon in IB

    // advanced filter state
    enum AdvancedFilterMode {
        case all
        case upcomingOnly
        case completedOnly
        case missedOnly
    }

    var advancedFilterMode: AdvancedFilterMode = .all
    var advancedSortByNearestDue: Bool = true    // sort preference


    let baseUpcomingVaccines: [VaccineItem] = [
        VaccineItem(name: "Tuberculosis", subtitle: "At Birth", dueDate: DateHelper.daysFromNow(0)),
        VaccineItem(name: "Poliomyelitis", subtitle: "6 Weeks", dueDate: DateHelper.daysFromNow(42)),
        VaccineItem(name: "Hepatitis B", subtitle: "10 Weeks", dueDate: DateHelper.daysFromNow(70)),
        VaccineItem(name: "DTP Vaccine", subtitle: "14 Weeks", dueDate: DateHelper.daysFromNow(98)),
        VaccineItem(name: "Measles", subtitle: "9 Months", dueDate: DateHelper.monthsFromNow(9)),
        VaccineItem(name: "MMR", subtitle: "12 Months", dueDate: DateHelper.monthsFromNow(12))
    ]

    let baseCompletedVaccines: [VaccineItem] = [
        VaccineItem(name: "Rotavirus", subtitle: "6 Weeks", dueDate: nil)
    ]


    // These are the filtered lists shown in UI
    var upcomingVaccines: [VaccineItem] = []
    var completedVaccines: [VaccineItem] = []


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
        
        upcomingVaccines = baseUpcomingVaccines
        completedVaccines = baseCompletedVaccines



        
//        styleBottomBar()
        setupFiltersCollectionView()
        setupVaccinesTableView()
    }

    @IBAction func advancedFilterTapped(_ sender: Any) {
        let sheet = UIAlertController(title: "Filter & Sort", message: nil, preferredStyle: .actionSheet)

        // Show group
        sheet.addAction(UIAlertAction(title: "Show: All", style: .default) { _ in
            self.advancedFilterMode = .all
            self.applyAdvancedFilterAndSort()
        })
        sheet.addAction(UIAlertAction(title: "Show: Upcoming only", style: .default) { _ in
            self.advancedFilterMode = .upcomingOnly
            self.applyAdvancedFilterAndSort()
        })
        sheet.addAction(UIAlertAction(title: "Show: Completed only", style: .default) { _ in
            self.advancedFilterMode = .completedOnly
            self.applyAdvancedFilterAndSort()
        })
        sheet.addAction(UIAlertAction(title: "Show: Missed / Skipped", style: .default) { _ in
            self.advancedFilterMode = .missedOnly
            self.applyAdvancedFilterAndSort()
        })

        
        // Separator-like neutral action (useful grouping)
        sheet.addAction(UIAlertAction(title: "— Sort —", style: .default, handler: nil))

        // Sort options
        sheet.addAction(UIAlertAction(title: "Sort: Nearest due date", style: .default) { _ in
            self.advancedSortByNearestDue = true
            self.applyAdvancedFilterAndSort()
        })
        sheet.addAction(UIAlertAction(title: "Sort: Name (A → Z)", style: .default) { _ in
            self.advancedSortByNearestDue = false
            self.applyAdvancedFilterAndSort()
        })

        // Reset
        sheet.addAction(UIAlertAction(title: "Reset filters", style: .destructive) { _ in
            self.advancedFilterMode = .all
            self.advancedSortByNearestDue = true
            self.selectedFilterIndex = 0
            self.applyFilter()          // keep chip selection logic intact
            self.applyAdvancedFilterAndSort()
        })

        // Cancel
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // For iPad: anchor to the button
        if let popover = sheet.popoverPresentationController, let btn = sender as? UIView {
            popover.sourceView = btn
            popover.sourceRect = btn.bounds
        }

        present(sheet, animated: true)
    }
    
    struct DateHelper {
        static func daysFromNow(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: Date())!
        }

        static func monthsFromNow(_ months: Int) -> Date {
            Calendar.current.date(byAdding: .month, value: months, to: Date())!
        }
    }


    func applyAdvancedFilterAndSort() {
        // First start with the results of chip-based filtering (so chips + advanced filters combine)
        // applyFilter() already sets upcomingVaccines & completedVaccines from base arrays
        // We'll copy current visible arrays, then apply advanced rules on top.

        // Ensure chip base is applied first
        applyFilter() // this updates upcomingVaccines/completedVaccines from chip selection

        // Now filter by advancedFilterMode
        switch advancedFilterMode {
        case .all:
            // nothing extra
            break
        case .upcomingOnly:
            completedVaccines = []
        case .completedOnly:
            upcomingVaccines = []
        case .missedOnly:
            upcomingVaccines = baseUpcomingVaccines.filter {
                $0.subtitle.lowercased().contains("skip") || $0.subtitle.lowercased().contains("miss")
            }
            completedVaccines = baseCompletedVaccines.filter {
                $0.subtitle.lowercased().contains("skip") || $0.subtitle.lowercased().contains("miss")
            }
        }

        // Combine lists for sorting if needed. We will sort each section individually.
//        if advancedSortByNearestDue {
//            // If you have a dueDate property, sort by it. For now we sort by name fallback.
//            // TODO: replace with actual date sorting when data model includes dueDate
//            upcomingVaccines.sort { $0.name < $1.name }   // placeholder: alphabetical as fallback
//            completedVaccines.sort { $0.name < $1.name }
//        } else {
//            // sort by name alphabetically
//            upcomingVaccines.sort { $0.name.lowercased() < $1.name.lowercased() }
//            completedVaccines.sort { $0.name.lowercased() < $1.name.lowercased() }
//        }

        if advancedSortByNearestDue {
            upcomingVaccines.sort {
                guard let d1 = $0.dueDate, let d2 = $1.dueDate else { return false }
                return d1 < d2
            }
            completedVaccines.sort {
                guard let d1 = $0.dueDate, let d2 = $1.dueDate else { return false }
                return d1 < d2
            }
        } else {
            upcomingVaccines.sort { $0.name.lowercased() < $1.name.lowercased() }
            completedVaccines.sort { $0.name.lowercased() < $1.name.lowercased() }
        }


        // update UI
        DispatchQueue.main.async {
            self.vaccinesTableView.reloadData()
        }
    }

    func updateAdvancedFilterButtonAppearance() {
        // Button appears active when not showing "All" or when sorting differs
        let isActive = (advancedFilterMode != .all) || (advancedSortByNearestDue == false)
        if isActive {
            advancedFilterButton.tintColor = UIColor.systemBlue
            // optionally change background circle
            advancedFilterButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            advancedFilterButton.layer.cornerRadius = 8
        } else {
            advancedFilterButton.tintColor = UIColor.label
            advancedFilterButton.backgroundColor = .clear
        }
    }

    
    func applyFilter() {
        let selected = filterOptions[selectedFilterIndex]

        if selected == "All" {
            upcomingVaccines = baseUpcomingVaccines
            completedVaccines = baseCompletedVaccines
        } else {
            // Filter based on subtitle (e.g., "At Birth", "6 Weeks")
            upcomingVaccines = baseUpcomingVaccines.filter { $0.subtitle == selected }
            completedVaccines = baseCompletedVaccines.filter { $0.subtitle == selected }
        }

        DispatchQueue.main.async {
            self.vaccinesTableView.reloadData()
        }
    }

    private func setupFiltersCollectionView() {
        let nib = UINib(nibName: "AgeFilterCell", bundle: nil)
            filtersCollectionView.register(nib, forCellWithReuseIdentifier: "AgeFilterCell")
            filtersCollectionView.showsHorizontalScrollIndicator = false

            // IMPORTANT: set delegate & datasource
            filtersCollectionView.delegate = self
            filtersCollectionView.dataSource = self

            // configure flow layout for horizontal scrolling
            if let layout = filtersCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = .horizontal
                layout.minimumInteritemSpacing = 8
                layout.minimumLineSpacing = 8
                layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            }
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
        let dueDate: Date?
    }


    func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }
    func monthsFromNow(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: Date())!
    }

    var selectedFilterIndex: Int = 0

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("DEBUG: filter tapped index = \(indexPath.item) -> \(filterOptions[indexPath.item])")
        selectedFilterIndex = indexPath.item

        // refresh chips so selected chip gets highlighted
        DispatchQueue.main.async {
            collectionView.reloadData()
        }

        // apply filter to vaccines and reload table
        applyFilter()

        // scroll table to top (nice UX)
        if vaccinesTableView.numberOfSections > 0, vaccinesTableView.numberOfRows(inSection: 0) > 0 {
            vaccinesTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        } else {
            // if no rows in section 0, scroll to top of table
            vaccinesTableView.setContentOffset(.zero, animated: true)
        }

        // make sure selected chip is visible in center
        filtersCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
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
//            let isSelected = (indexPath.item == 0) For now, make "All" look selected
            
//            cell.configure(with: title, isSelected: isSelected)
//            print("cellForItemAt for index", indexPath.item)
            
            let isSelected = (indexPath.item == selectedFilterIndex)
            cell.configure(with: title, isSelected: isSelected)

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
                ) as? VaccineCell else { return UITableViewCell() }

                let source = indexPath.section == 0 ? upcomingVaccines : completedVaccines

                guard indexPath.row < source.count else {
                    print("⚠️ cellForRowAt out of range. Reloading table...")
                    DispatchQueue.main.async { tableView.reloadData() }
                    return UITableViewCell()
                }

                let item = source[indexPath.row]
                cell.configure(name: item.name, subtitle: item.subtitle)
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
    
    // Add this inside your VaccinationViewController class
    // Safe didSelectRowAt — paste inside your ViewController class
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("DEBUG: didSelectRowAt called for section:\(indexPath.section) row:\(indexPath.row)")
        print("DEBUG: upcoming count = \(upcomingVaccines.count), completed count = \(completedVaccines.count)")

        // Ensure section is valid (0 or 1)
        guard indexPath.section == 0 || indexPath.section == 1 else {
            print("DEBUG: invalid section \(indexPath.section)")
            return
        }

        // Choose the array based on section
        let sourceArray = (indexPath.section == 0) ? upcomingVaccines : completedVaccines

        // Guard row index within bounds
        guard indexPath.row >= 0 && indexPath.row < sourceArray.count else {
            print("DEBUG: tapped row \(indexPath.row) out of range for section \(indexPath.section) (count = \(sourceArray.count)).")
            // Optionally: attempt to correct by reloading and returning
            DispatchQueue.main.async {
                self.vaccinesTableView.reloadData()
            }
            return
        }

        // Safe to fetch item
        let item = sourceArray[indexPath.row]
        print("DEBUG: presenting detail for item: \(item.name)")

        // Instantiate and present detail VC
        let vc = VaccineDetailViewController(nibName: "VaccineDetailViewController", bundle: nil)
        vc.vaccineName = item.name
        vc.vaccineDescription = item.subtitle
        vc.headerTintColor = UIColor.systemBlue

        // present as card (uses presentAsCard helper in detail VC)
        DispatchQueue.main.async {
            vc.presentAsCard(on: self)
        }
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

