//
//  VaccineDetailViewController.swift
//  Vaccination
//
//  Created by user66 on 11/12/25.
//

import UIKit
import PhotosUI

class VaccineDetailViewController: UIViewController , PHPickerViewControllerDelegate {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var dateValueLabel: UILabel!
    @IBOutlet weak var timeValueLabel: UILabel!

    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var addPhotoButton: UIButton!


    @IBOutlet weak var statusTakenButton: UIButton!
    @IBOutlet weak var statusSkippedButton: UIButton!
    @IBOutlet weak var statusRescheduleButton: UIButton!
    @IBOutlet weak var photoPreviewImageView: UIImageView!


    @IBOutlet weak var saveButton: UIButton!

   
    // MARK: - Config / state
     var vaccineName: String?
     var vaccineDescription: String? // sraeyes
     var headerTintColor: UIColor = .systemBlue
     private var selectedStatus: String?
     private var selectedImage: UIImage?
    

     // MARK: - Lifecycle
     override func viewDidLoad() {
         super.viewDidLoad()

         // dim background
//         view.backgroundColor = UIColor.black.withAlphaComponent(0.25)

         // safety: ensure cardView rounded
         cardView.layer.cornerRadius = 22
         cardView.clipsToBounds = true

//         photoPreviewImageView.isHidden = true
         // add tap gesture on preview image to re-open picker
                 let tap = UITapGestureRecognizer(target: self, action: #selector(photoPreviewTapped(_:)))
                 photoPreviewImageView.addGestureRecognizer(tap)
         
         setupUI()
         bindData()
         
         
     }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // rounded header corners (visual)
        headerView.layer.cornerRadius = 18
        headerView.clipsToBounds = true
    }

    
    @objc private func photoPreviewTapped(_ gesture: UITapGestureRecognizer) {
        presentImagePicker()
    }


     // MARK: - UI Setup
     private func setupUI() {
         // header styling
//         headerView.backgroundColor = headerTintColor
//         titleLabel.textColor = .white
//         titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
//         titleLabel.textAlignment = .center

         // description (ensure visible on colored header)
//         descriptionLabel.textColor = UIColor(white: 1.0, alpha: 0.95)
//         descriptionLabel.numberOfLines = 0
//         descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
//         descriptionLabel.textAlignment = .left

         // date/time placeholders
         dateValueLabel.text = formattedDate(Date())
         timeValueLabel.text = formattedTime(Date())

         // notes placeholder style
         notesTextView.text = "Add a note"
         notesTextView.textColor = .secondaryLabel
         notesTextView.layer.cornerRadius = 12
         notesTextView.clipsToBounds = true
//         notesTextView.backgroundColor = .systemBackground

         // save button
//         saveButton.backgroundColor = headerTintColor.darker()
//         saveButton.layer.cornerRadius = 24
//         saveButton.setTitleColor(.white, for: .normal)

         // status rows
         [statusTakenButton, statusSkippedButton, statusRescheduleButton].forEach { btn in
             btn?.contentHorizontalAlignment = .left
             btn?.layer.cornerRadius = 10
             btn?.layer.borderWidth = 0.5
             btn?.layer.borderColor = UIColor.systemGray4.cgColor
             btn?.setTitleColor(.label, for: .normal)
         }
     }

     private func bindData() {
         titleLabel.text = vaccineName ?? "Vaccine"
         descriptionLabel.text = vaccineDescription ?? "" // will now be visible
     }

     // MARK: - Helpers
     private func formattedDate(_ date: Date) -> String {
         let df = DateFormatter()
         df.dateStyle = .medium
         return df.string(from: date)
     }
     private func formattedTime(_ date: Date) -> String {
         let tf = DateFormatter()
         tf.timeStyle = .short
         return tf.string(from: date)
     }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        // If user cancelled (no results), just return
                guard let item = results.first else {
                    // no selection (user tapped Cancel) — we already dismissed
                    return
                }
        let provider = item.itemProvider
//        guard let provider = results.first?.itemProvider else { return }

                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        guard let self = self else { return }
                        if let img = image as? UIImage {
                            DispatchQueue.main.async {
                                self.selectedImage = img

                                   // Show big preview (MAIN FIX)
                                   self.photoPreviewImageView.image = img
                                   self.photoPreviewImageView.contentMode = .scaleAspectFill
                                   self.photoPreviewImageView.clipsToBounds = true
                                   self.photoPreviewImageView.layer.cornerRadius = 12
                                   self.photoPreviewImageView.isHidden = false

                                   // Hide add button
                                   self.addPhotoButton.isHidden = true

                            }
                        }
                    }
                }
    }
    
     // MARK: - IBActions
     @IBAction func dateTapped(_ sender: Any) {
         // simple date picker sheet
         let alert = UIAlertController(title: "Select Date", message: nil, preferredStyle: .actionSheet)
         let picker = UIDatePicker(frame: .zero)
         picker.datePickerMode = .date
         if #available(iOS 26.0, *) { picker.preferredDatePickerStyle = .wheels }
         alert.view.addSubview(picker)
         picker.translatesAutoresizingMaskIntoConstraints = false
         NSLayoutConstraint.activate([
             picker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor),
             picker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor),
             picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
             picker.heightAnchor.constraint(equalToConstant: 200)
         ])
         alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
             self.dateValueLabel.text = self.formattedDate(picker.date)
         }))
         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
         present(alert, animated: true)
     }

     @IBAction func addPhotoTapped(_ sender: Any) {
         var config = PHPickerConfiguration(photoLibrary: .shared())
         config.selectionLimit = 1
         config.filter = .images

         let picker = PHPickerViewController(configuration: config)
         picker.delegate = self
         picker.modalPresentationStyle = .fullScreen
         present(picker, animated: true, completion: nil)
         

     }
    
    // helper to present the picker
      private func presentImagePicker() {
          var config = PHPickerConfiguration(photoLibrary: .shared())
          config.selectionLimit = 1
          config.filter = .images

          let picker = PHPickerViewController(configuration: config)
          picker.delegate = self
          picker.modalPresentationStyle = .fullScreen   // prevents some sheet dismissal issues
          present(picker, animated: true, completion: nil)
      }

     @IBAction func statusButtonTapped(_ sender: UIButton) {
         // highlight selected status
         [statusTakenButton, statusSkippedButton, statusRescheduleButton].forEach {
             $0?.backgroundColor = .clear
             $0?.setTitleColor(.label, for: .normal)
         }
         sender.backgroundColor = headerTintColor.withAlphaComponent(0.16)
         sender.setTitleColor(headerTintColor, for: .normal)
         selectedStatus = sender.title(for: .normal)
     }

     @IBAction func saveTapped(_ sender: Any) {
         // gather values
         let date = dateValueLabel.text ?? ""
         let time = timeValueLabel.text ?? ""
         let notes = notesTextView.text ?? ""
         let status = selectedStatus ?? "Taken"
         print("Save pressed:", date, time, notes, status)

         // dismiss
         dismissAnimatedCard()
     }

     // MARK: - Presentation helpers
     func presentAsCard(on parent: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
         modalPresentationStyle = .overCurrentContext
         modalTransitionStyle = .crossDissolve
         parent.present(self, animated: false) {
             guard animated else { completion?(); return }
             // animate card from bottom
             self.cardView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
             UIView.animate(withDuration: 0.32,
                            delay: 0,
                            usingSpringWithDamping: 0.85,
                            initialSpringVelocity: 0.6,
                            options: [.curveEaseOut]) {
                 self.cardView.transform = .identity
             } completion: { _ in completion?() }
         }
     }

     func dismissAnimatedCard(animated: Bool = true, completion: (() -> Void)? = nil) {
         guard animated else { dismiss(animated: false, completion: completion); return }
         UIView.animate(withDuration: 0.22, animations: {
             self.cardView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
             self.view.backgroundColor = .clear
         }) { _ in
             self.dismiss(animated: false, completion: completion)
         }
     }
 }

 // MARK: - small UIColor helper
// extension UIColor {
//     func darker(by percent: CGFloat = 0.20) -> UIColor {
//         var r: CGFloat=0,g:CGFloat=0,b:CGFloat=0,a:CGFloat=0
//         if getRed(&r, green: &g, blue: &b, alpha: &a) {
//             return UIColor(red: max(r - percent, 0),
//                            green: max(g - percent, 0),
//                            blue: max(b - percent, 0),
//                            alpha: a)
//         }
//         return self
//     }
// }
