//
//  AddVaccineViewController.swift
//  Vaccination
//
//  Created by user66 on 12/12/25.
//

import UIKit

//protocol AddVaccineDelegate: AnyObject {
//    func addVaccineViewController(_ vc: AddVaccineViewController, didCreate vaccine: VaccineItem)
//}

class AddVaccineViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainStack: UIStackView!

    // Header
//    @IBOutlet weak var backButton: UIButton!
//    @IBOutlet weak var titleLabel: UILabel!

    // Vaccination Against
    @IBOutlet weak var againstTextField: UITextField!
    @IBOutlet weak var againstCardView: UIView!

    // Vaccination Name
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameCardView: UIView!

    // Description
    @IBOutlet weak var descriptionTextView: UITextView!
//    @IBOutlet weak var descriptionCardView: UIView!

    // Type Selection
//    @IBOutlet weak var typeCardView: UIView!
    @IBOutlet weak var routineButton: UIButton!         // radio-like button for routine
    @IBOutlet weak var asNeededButton: UIButton!        // radio-like button for as-needed
    @IBOutlet weak var routineSubtitleLabel: UILabel!
    @IBOutlet weak var asNeededSubtitleLabel: UILabel!

    // Save
    @IBOutlet weak var saveButton: UIButton!

    
    // MARK: state
    weak var delegate: AddVaccineDelegate?
//    weak var delegate: AddVaccineDelegate?


    private var isRoutineSelected: Bool = true {
        didSet { updateTypeSelectionUI() }
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerForKeyboardNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)

        // header
//        titleLabel.text = "Add New Vaccination"
//        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)

        // cards style
        [againstCardView, nameCardView].forEach { v in
            v?.layer.cornerRadius = 14
            v?.backgroundColor = UIColor.systemBackground
            v?.layer.shadowColor = UIColor.black.cgColor
            v?.layer.shadowOpacity = 0.03
            v?.layer.shadowOffset = CGSize(width: 0, height: 6)
            v?.layer.shadowRadius = 12
            v?.clipsToBounds = false
        }

        // text fields
        nameTextField.placeholder = "Enter Vaccination Name"
        againstTextField.placeholder = "Type vaccine name"

        // description text view placeholder
        descriptionTextView.text = "Vaccination Description..."
        descriptionTextView.textColor = .secondaryLabel
        descriptionTextView.layer.cornerRadius = 10
        descriptionTextView.backgroundColor = UIColor.secondarySystemBackground

        // save button
        saveButton.layer.cornerRadius = 28
        saveButton.backgroundColor = UIColor.systemPurple
        saveButton.setTitleColor(.white, for: .normal)

        // radio buttons
        updateTypeSelectionUI()

        // gestures
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func updateTypeSelectionUI() {
        // simple radio effect using tint and border
        func style(button: UIButton, selected: Bool) {
            button.layer.cornerRadius = 18
            button.layer.borderWidth = selected ? 0 : 1
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.backgroundColor = selected ? UIColor.systemPurple.withAlphaComponent(0.12) : UIColor.clear
            button.setTitleColor(selected ? UIColor.systemPurple : UIColor.label, for: .normal)
        }
        style(button: routineButton, selected: isRoutineSelected)
        style(button: asNeededButton, selected: !isRoutineSelected)
    }

    // MARK: Keyboard
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let bottom = frame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottom + 20
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
    @objc private func keyboardWillHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets = .zero
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: IBActions
    @IBAction func backTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func routineTapped(_ sender: Any) {
        isRoutineSelected = true
    }

    @IBAction func asNeededTapped(_ sender: Any) {
        isRoutineSelected = false
    }

    @IBAction func saveTapped(_ sender: Any) {
        // validation
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let against = againstTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//        let desc = (descriptionTextView.textColor == .secondaryLabel) ? "" : descriptionTextView.text

        guard !name.isEmpty else {
            showAlert(title: "Missing name", message: "Please enter vaccine name.")
            return
        }

        // Create VaccineItem (use your model)
        let vaccine = VaccineItem(name: name, subtitle: against.isEmpty ? (isRoutineSelected ? "Routine" : "As Needed") : against, dueDate: nil)

        // inform delegate
        delegate?.addVaccineViewController(self, didCreate: vaccine)

        // dismiss
        dismiss(animated: true, completion: nil)
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: UITextViewDelegate (placeholder behavior)
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .secondaryLabel {
            textView.text = ""
            textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Vaccination Description..."
            textView.textColor = .secondaryLabel
        }
    }
