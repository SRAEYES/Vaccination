//
//  ViewController.swift
//  Vaccination
//
//  Created by user66 on 10/12/25.
//

import UIKit

class ViewController: UIViewController,
                      UICollectionViewDataSource,
                      UICollectionViewDelegate,
                      UICollectionViewDelegateFlowLayout,
                      UITableViewDataSource,
                      UITableViewDelegate,
                      AddVaccineDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var filtersCollectionView: UICollectionView!
    @IBOutlet weak var vaccinesTableView: UITableView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var advancedFilterButton: UIButton!

    // MARK: - Advanced filter state
    enum AdvancedFilterMode {
        case all
        case upcomingOnly
        case completedOnly
        case missedOnly
    }

    var advancedFilterMode: AdvancedFilterMode = .all
    var advancedSortByNearestDue: Bool = true

    // MARK: - Data sources (use shared VaccineItem)
    var baseUpcomingVaccines: [VaccineItem] = [
        VaccineItem(name: "Tuberculosis", subtitle: "At Birth", dueDate: DateHelper.daysFromNow(0)),
        VaccineItem(name: "Poliomyelitis", subtitle: "6 Weeks", dueDate: DateHelper.daysFromNow(42)),
        VaccineItem(name: "Hepatitis B", subtitle: "10 Weeks", dueDate: DateHelper.daysFromNow(70)),
        VaccineItem(name: "DTP Vaccine", subtitle: "14 Weeks", dueDate: DateHelper.daysFromNow(98)),
        VaccineItem(name: "Measles", subtitle: "9 Months", dueDate: DateHelper.monthsFromNow(9)),
        VaccineItem(name: "MMR", subtitle: "12 Months", dueDate: DateHelper.monthsFromNow(12))
    ]

    var baseCompletedVaccines: [VaccineItem] = [
        VaccineItem(name: "Rotavirus", subtitle: "6 Weeks", dueDate: nil)
    ]

    // filtered lists shown in UI
    var upcomingVaccines: [VaccineItem] = []
    var completedVaccines: [VaccineItem] = []

    let filterOptions = ["All", "At Birth", "6 Weeks", "10 Weeks", "14 Weeks", "6 Months", "9 Months", "12 Months", "18 Months", "5 Years", "10 Years", "14 Years"]

    var selectedFilterIndex: Int = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load persisted base list (if you want persistence)
        let loaded = VaccineStorage.loadBaseUpcoming()
        if !loaded.isEmpty {
            baseUpcomingVaccines = loaded
        } // else keep the defaults above

        // initial filtered lists
        upcomingVaccines = baseUpcomingVaccines
        completedVaccines = baseCompletedVaccines

        // table setup
        vaccinesTableView.backgroundColor = .clear
        vaccinesTableView.separatorStyle = .none
        vaccinesTableView.estimatedRowHeight = 88
        vaccinesTableView.rowHeight = UITableView.automaticDimension

        // set bottom inset so floating bottomBar doesn't cover content
        let bottomInset: CGFloat = bottomBar.bounds.height + 24
        vaccinesTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        vaccinesTableView.scrollIndicatorInsets = vaccinesTableView.contentInset

        setupFiltersCollectionView()
        setupVaccinesTableView()
    }

    // MARK: - Add custom vaccine (present add screen)
    @IBAction func addCustomVaccineTapped(_ sender: Any) {
        let addVC = AddVaccineViewController(nibName: "AddVaccineViewController", bundle: nil)
        addVC.delegate = self
        addVC.modalPresentationStyle = .overCurrentContext
        addVC.modalTransitionStyle = .crossDissolve
        present(addVC, animated: true, completion: nil)
    }

    // MARK: - AddVaccineDelegate implementation
    func addVaccineViewController(_ vc: AddVaccineViewController, didCreate vaccine: VaccineItem) {
        // append to base, persist, re-apply filters and UI update
        baseUpcomingVaccines.append(vaccine)
        VaccineStorage.saveBaseUpcoming(baseUpcomingVaccines)

        // reapply chip filter and advanced sort/filter
        applyFilter()
        applyAdvancedFilterAndSort()

        DispatchQueue.main.async {
            if let idx = self.upcomingVaccines.firstIndex(where: { $0.id == vaccine.id }) {
                let ip = IndexPath(row: idx, section: 0)
                if self.vaccinesTableView.numberOfSections > 0 && idx <= self.vaccinesTableView.numberOfRows(inSection: 0) {
//                    self.vaccinesTableView.insertRows(at: [ip], with: .automatic)
                    self.vaccinesTableView.scrollToRow(at: ip, at: .middle, animated: true)
                    return
                }
            }
            self.vaccinesTableView.reloadData()
        }
    }

    // MARK: - Advanced filter sheet
    @IBAction func advancedFilterTapped(_ sender: Any) {
        let sheet = UIAlertController(title: "Filter & Sort", message: nil, preferredStyle: .actionSheet)

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

        sheet.addAction(UIAlertAction(title: "— Sort —", style: .default, handler: nil))

        sheet.addAction(UIAlertAction(title: "Sort: Nearest due date", style: .default) { _ in
            self.advancedSortByNearestDue = true
            self.applyAdvancedFilterAndSort()
        })
        sheet.addAction(UIAlertAction(title: "Sort: Name (A → Z)", style: .default) { _ in
            self.advancedSortByNearestDue = false
            self.applyAdvancedFilterAndSort()
        })

        sheet.addAction(UIAlertAction(title: "Reset filters", style: .destructive) { _ in
            self.advancedFilterMode = .all
            self.advancedSortByNearestDue = true
            self.selectedFilterIndex = 0
            self.applyFilter()
            self.applyAdvancedFilterAndSort()
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if let popover = sheet.popoverPresentationController, let btn = sender as? UIView {
            popover.sourceView = btn
            popover.sourceRect = btn.bounds
        }
        present(sheet, animated: true)
    }

    // MARK: - Date helper struct (keep static)
    struct DateHelper {
        static func daysFromNow(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: Date())!
        }
        static func monthsFromNow(_ months: Int) -> Date {
            Calendar.current.date(byAdding: .month, value: months, to: Date())!
        }
    }

    // MARK: - Filtering & sorting logic
    func applyAdvancedFilterAndSort() {
        // ensure chip filter applied
        applyFilter()

        switch advancedFilterMode {
        case .all: break
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

        if advancedSortByNearestDue {
            upcomingVaccines.sort {
                guard let d1 = $0.dueDate, let d2 = $1.dueDate else { return $0.name < $1.name }
                return d1 < d2
            }
            completedVaccines.sort {
                guard let d1 = $0.dueDate, let d2 = $1.dueDate else { return $0.name < $1.name }
                return d1 < d2
            }
        } else {
            upcomingVaccines.sort { $0.name.lowercased() < $1.name.lowercased() }
            completedVaccines.sort { $0.name.lowercased() < $1.name.lowercased() }
        }

        DispatchQueue.main.async { self.vaccinesTableView.reloadData() }
    }

    func updateAdvancedFilterButtonAppearance() {
        let isActive = (advancedFilterMode != .all) || (advancedSortByNearestDue == false)
        if isActive {
            advancedFilterButton.tintColor = .systemBlue
            advancedFilterButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            advancedFilterButton.layer.cornerRadius = 8
        } else {
            advancedFilterButton.tintColor = .label
            advancedFilterButton.backgroundColor = .clear
        }
    }

    func applyFilter() {
        let selected = filterOptions[selectedFilterIndex]
        if selected == "All" {
            upcomingVaccines = baseUpcomingVaccines
            completedVaccines = baseCompletedVaccines
        } else {
            upcomingVaccines = baseUpcomingVaccines.filter { $0.subtitle == selected }
            completedVaccines = baseCompletedVaccines.filter { $0.subtitle == selected }
        }
        DispatchQueue.main.async { self.vaccinesTableView.reloadData() }
    }

    // MARK: - Collection view setup
    private func setupFiltersCollectionView() {
        let nib = UINib(nibName: "AgeFilterCell", bundle: nil)
        filtersCollectionView.register(nib, forCellWithReuseIdentifier: "AgeFilterCell")
        filtersCollectionView.showsHorizontalScrollIndicator = false
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self

        if let layout = filtersCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 8
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        }
    }

    // MARK: - Table setup
    private func setupVaccinesTableView() {
        vaccinesTableView.delegate = self
        vaccinesTableView.dataSource = self
        let nib = UINib(nibName: "VaccineCell", bundle: nil)
        vaccinesTableView.register(nib, forCellReuseIdentifier: "VaccineCell")
        vaccinesTableView.separatorStyle = .none
    }

    // MARK: - Collection DataSource/Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterOptions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AgeFilterCell", for: indexPath) as? AgeFilterCell else {
            return UICollectionViewCell()
        }
        let title = filterOptions[indexPath.item]
        let isSelected = (indexPath.item == selectedFilterIndex)
        cell.configure(with: title, isSelected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilterIndex = indexPath.item
        collectionView.reloadData()
        applyFilter()
        if vaccinesTableView.numberOfSections > 0, vaccinesTableView.numberOfRows(inSection: 0) > 0 {
            vaccinesTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        } else {
            vaccinesTableView.setContentOffset(.zero, animated: true)
        }
        filtersCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 32)
    }

    // MARK: - Table DataSource/Delegate
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? upcomingVaccines.count : completedVaccines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VaccineCell", for: indexPath) as? VaccineCell else {
            return UITableViewCell()
        }

        let source = indexPath.section == 0 ? upcomingVaccines : completedVaccines

        guard indexPath.row < source.count else {
            DispatchQueue.main.async { tableView.reloadData() }
            return UITableViewCell()
        }

        let item = source[indexPath.row]
        cell.configure(name: item.name, subtitle: item.subtitle)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Upcoming" : "Completed"
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 80 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 || indexPath.section == 1 else { return }
        let sourceArray = (indexPath.section == 0) ? upcomingVaccines : completedVaccines
        guard indexPath.row >= 0 && indexPath.row < sourceArray.count else {
            DispatchQueue.main.async { self.vaccinesTableView.reloadData() }
            return
        }
        let item = sourceArray[indexPath.row]
        let vc = VaccineDetailViewController(nibName: "VaccineDetailViewController", bundle: nil)
        vc.vaccineName = item.name
        vc.vaccineDescription = item.subtitle
        vc.headerTintColor = UIColor.systemBlue
        DispatchQueue.main.async { vc.presentAsCard(on: self) }
    }

    // MARK: - bottom bar styling
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        styleBottomBar()
    }

    private func styleBottomBar() {
        bottomBar.layer.cornerRadius = bottomBar.bounds.height / 2
        bottomBar.layer.masksToBounds = false
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.15
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: 10)
        bottomBar.layer.shadowRadius = 20
        if let blurView = bottomBar.subviews.first as? UIVisualEffectView {
            blurView.layer.cornerRadius = bottomBar.bounds.height / 2
            blurView.clipsToBounds = true
        }
    }
}

