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
        
        for i in 0..<Int(duration * frameRate) {
            let time = CMTimeMakeWithSeconds(Double(i) / frameRate, preferredTimescale: 600)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            var actualTime: CMTime = CMTimeMake(value: 0, timescale: 0)
            guard let cgImage = try? generator.copyCGImage(at: time, actualTime: &actualTime) else {
                continue
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            imageArray.append(uiImage)
        }
        tableView.reloadData()
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
