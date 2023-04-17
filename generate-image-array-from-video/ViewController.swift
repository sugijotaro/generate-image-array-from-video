//
//  TableViewController.swift
//  generate-image-array-from-video
//
//  Created by JotaroSugiyama on 2023/02/18.
//

import UIKit
import AVFoundation

class TableViewController: UITableViewController, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    var videoURL: URL? {
        didSet {
            prepareImages()
        }
    }
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        imagePicker.allowsEditing = true
    }
    
    @IBAction func generateButtonTapped(_ sender: Any) {
        imageArray = []
        tableView.reloadData()
        present(imagePicker, animated: true, completion: nil)
    }
    
    func prepareImages() {
        guard let url = videoURL else {
            return
        }
        
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let frameRate = 6.0
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        
        let times = stride(from: 0.0, to: duration, by: 1.0 / frameRate).map { CMTimeMakeWithSeconds($0, preferredTimescale: 600) }
        
        let dispatchGroup = DispatchGroup()
        
        for time in times {
            dispatchGroup.enter()
            
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let error = error {
                    print("Failed to generate CGImage at time: \(time), with error: \(error.localizedDescription)")
                } else if let cgImage = cgImage {
                    let compressedImageData = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.5)!
                    let compressedImage = UIImage(data: compressedImageData)!
                    DispatchQueue.main.async {
                        self.imageArray.append(compressedImage)
                        print("Generated and appended image for time: \(time)")
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.imageView?.image = imageArray[indexPath.row]
        return cell
    }
}

extension TableViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == "public.movie" else {
            return
        }
        
        guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            return
        }
        videoURL = url
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
