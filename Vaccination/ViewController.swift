//
//  ViewController.swift
//  Vaccination
//
//  Created by user66 on 10/12/25.
//

import UIKit
import FSCalendar


class ViewController: UIViewController , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UITableViewDataSource, UITableViewDelegate,FSCalendarDelegate, FSCalendarDataSource {
    
    private var calendarPopup: FSCalendar?
    private var dimmingView: UIView?
    // holds vaccine/event dates normalized to midnight
    private var eventDatesSet: Set<Date> = []

    // convenience calendar
    private let localCalendar = Calendar.current


    @IBOutlet weak var filtersCollectionView: UICollectionView!
    @IBOutlet weak var vaccinesTableView: UITableView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var calendarButton: UIButton!



    let filterOptions = ["All", "At Birth", "6 Weeks", "10 Weeks", "14 Weeks", "6 Months", "9 Months", "12 Months", "18 Months", "5 Years", "10 Years", "14 Years"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // table setup
            vaccinesTableView.backgroundColor = .clear
            vaccinesTableView.separatorStyle = .none
            vaccinesTableView.estimatedRowHeight = 88
            vaccinesTableView.rowHeight = UITableView.automaticDimension

        
        let today = Date()
           if let d1 = localCalendar.date(byAdding: .day, value: 3, to: today),
              let d2 = localCalendar.date(byAdding: .day, value: 10, to: today),
              let d3 = localCalendar.date(byAdding: .month, value: 1, to: today) {
               eventDatesSet.insert(localCalendar.startOfDay(for: d1))
               eventDatesSet.insert(localCalendar.startOfDay(for: d2))
               eventDatesSet.insert(localCalendar.startOfDay(for: d3))
           }

            // Add bottom content inset equal to bottomBar height + extra
            let bottomInset: CGFloat = bottomBar.bounds.height + 24
            vaccinesTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
            vaccinesTableView.scrollIndicatorInsets = vaccinesTableView.contentInset
    

        calendarButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)

//        styleBottomBar()
        setupFiltersCollectionView()
        setupVaccinesTableView()
    }

    @objc func avatarTapped() {
//        showChildMenu()
    }

    @objc func calendarTapped() {
        if calendarPopup == nil {
            showCalendarPopup()
        } else {
            hideCalendarPopup()
        }
    }

    func showCalendarPopup() {

        // 1) Dimming background
        let dim = UIView(frame: view.bounds)
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        dim.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideCalendarPopup))
        dim.addGestureRecognizer(tap)
        view.addSubview(dim)
        dim.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dim.topAnchor.constraint(equalTo: view.topAnchor),
            dim.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.dimmingView = dim

        // 2) FSCalendar view
        let calendar = FSCalendar()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.layer.cornerRadius = 16
        calendar.clipsToBounds = true
        calendar.scope = .month
        calendar.backgroundColor = UIColor(red: 0.93, green: 0.94, blue: 1.0, alpha: 1)

        calendar.dataSource = self
        calendar.delegate = self

        // after `let calendar = FSCalendar()` and before adding it to the view:
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.layer.cornerRadius = 16
        calendar.clipsToBounds = true
        calendar.scope = .month
        calendar.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 1.0, alpha: 1.0)

        // Appearance: use built-in appearance settings (no delegate needed)
        calendar.appearance.headerTitleColor = .label
        calendar.appearance.weekdayTextColor = .secondaryLabel
        calendar.appearance.titleDefaultColor = .label
        calendar.appearance.titlePlaceholderColor = .secondaryLabel   // <— dates outside month
        calendar.appearance.titleTodayColor = .white
        calendar.appearance.todayColor = UIColor.systemGray4
        calendar.appearance.selectionColor = UIColor.systemBlue
        calendar.firstWeekday = 1

        // styling
        calendar.appearance.headerTitleColor = .label
        calendar.appearance.weekdayTextColor = .secondaryLabel
        calendar.appearance.todayColor = UIColor.systemGray4
        calendar.appearance.titleTodayColor = .label
        calendar.appearance.selectionColor = UIColor.systemBlue

        view.addSubview(calendar)
        calendarPopup = calendar

        // 3) Anchor under the calendar button
        let btnFrame = calendarButton.superview?.convert(calendarButton.frame, to: view) ?? calendarButton.frame
        let topY = btnFrame.maxY + 8
        let width: CGFloat = min(360, view.bounds.width - 32)

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.topAnchor, constant: topY),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            calendar.widthAnchor.constraint(equalToConstant: width),
            calendar.heightAnchor.constraint(equalToConstant: 320)
        ])

        // 4) Animation
        calendar.alpha = 0
        calendar.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.25, delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseOut) {
            dim.alpha = 1
            calendar.alpha = 1
            calendar.transform = .identity
        }
    }

    @objc func hideCalendarPopup() {
        guard let cal = calendarPopup, let dim = dimmingView else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            cal.alpha = 0
            cal.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            dim.alpha = 0
        }) { _ in
            cal.removeFromSuperview()
            dim.removeFromSuperview()
            self.calendarPopup = nil
            self.dimmingView = nil
        }
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

//    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
//           print("Selected date:", date)
//           // Use date here for filtering, etc.
//           hideCalendarPopup()
//       }

       // Optional: dim dates outside month
    // implement in your VC
    // FSCalendarDataSource
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let d = localCalendar.startOfDay(for: date)
        return eventDatesSet.contains(d) ? 1 : 0
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("selected: \(date)")
        hideCalendarPopup()
    }


}

