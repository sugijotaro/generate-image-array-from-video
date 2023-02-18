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
            imageCache.removeAllObjects()
            tableView.reloadData()
        }
    }
    let imageCache = NSCache<NSNumber, UIImage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        imagePicker.allowsEditing = true
    }
    
    @IBAction func generateButtonTapped(_ sender: Any) {
        tableView.reloadData()
        present(imagePicker, animated: true, completion: nil)
    }
    
    func generateImage(for index: Int) -> UIImage? {
        if let cachedImage = imageCache.object(forKey: NSNumber(value: index)) {
            return cachedImage
        }
        
        guard let url = videoURL else {
            return nil
        }
        
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let frameRate = 6.0
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTimeMakeWithSeconds(Double(index) / frameRate, preferredTimescale: 600)
        
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        
        let compressedImageData = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.5)!
        let compressedImage = UIImage(data: compressedImageData)!
        imageCache.setObject(compressedImage, forKey: NSNumber(value: index))
        return compressedImage
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let url = videoURL else {
            return 0
        }
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let frameRate = 6.0
        return Int(duration * frameRate)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let image = generateImage(for: indexPath.row) {
            cell.imageView?.image = image
        }
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
