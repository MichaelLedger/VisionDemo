//
//  PhotoPickerViewController.swift
//  FaceCaptureQuality_iOS
//
//  Created by Gavin Xiang on 2023/3/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos

class PhotoPickerViewController: UIViewController,TLPhotosPickerViewControllerDelegate {
    var selectedAssets = [PHAsset]()
    
    private var iv = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let viewController = TLPhotosPickerViewController()
        viewController.delegate = self
        //var configure = TLPhotosPickerConfigure()
        //configure.nibSet = (nibName: "CustomCell_Instagram", bundle: Bundle.main) // If you want use your custom cell..
        self.present(viewController, animated: true, completion: nil)
        
        iv.frame = self.view.bounds
        view.addSubview(iv)
    }
    
    //TLPhotosPickerViewControllerDelegate
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        // use selected order, fullresolution image
        selectedAssets.removeAll()
        withTLPHAssets.forEach { tlPHAsset in
            if tlPHAsset.phAsset != nil {
                selectedAssets.append(tlPHAsset.phAsset!)
            }
        }
        self.findBestPhotoForAlbumCover(withAssets: selectedAssets) { [weak self] (bestPhoto)  in
            self?.iv.image = bestPhoto
        }
        return true
    }
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
    }
    func photoPickerDidCancel() {
        // cancel
    }
    func dismissComplete() {
        // picker viewcontroller dismiss completion
    }
    func canSelectAsset(phAsset: PHAsset) -> Bool {
        //Custom Rules & Display
        //You can decide in which case the selection of the cell could be forbidden.
        return true
    }
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        // exceed max selection
    }
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        // handle denied albums permissions case
    }
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        // handle denied camera permissions case
    }
}

import Vision
extension PhotoPickerViewController {
    func findBestPhotoForAlbumCover(withAssets assets: [PHAsset], completion: @escaping (UIImage?) -> Void) {
        
        // Create a dispatch group to track progress
        let dispatchGroup = DispatchGroup()
        
        // Define variables to store the best photo and its score
        var bestPhoto: PHAsset?
        var bestScore: Float = 0
        
        // Loop through each asset in the array
        for asset in assets {
            
            // Enter the dispatch group
            dispatchGroup.enter()
            
            // Load the asset image data
            PHImageManager.default().requestImageData(for: asset, options: nil) { imageData, _, _, _ in
                
                // Make sure image data exists
                guard let imageData = imageData else {
                    dispatchGroup.leave()
                    return
                }
                
                // Use Apple Vision to analyze the image and get a score
                let visionRequestHandler = VNImageRequestHandler(data: imageData, options: [:])
                // VNImageBasedRequest: The abstract superclass for image analysis requests that focus on a specific part of an image.
                // VNDetectFaceRectanglesRequest
                let visionRequest = VNClassifyImageRequest { request, error in
                    guard let observations = request.results as? [VNClassificationObservation], let topResult = observations.first else {
                        return
                    }
                    let score = topResult.confidence
                    print("score:\(score)")
                    
                    // Check if this is the best score so far
                    if score > bestScore {
                        bestScore = score
                        bestPhoto = asset
                    }
                    
                    // Leave the dispatch group
                    dispatchGroup.leave()
                }
                try? visionRequestHandler.perform([visionRequest])
            }
        }
        
        // When all tasks are complete, return the best photo
        dispatchGroup.notify(queue: .main) {
            guard let bestPhoto = bestPhoto else {
                completion(nil)
                return
            }
            PHImageManager.default().requestImage(for: bestPhoto, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { image, _ in
                completion(image)
            }
        }
    }
}
