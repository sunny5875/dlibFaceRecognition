//
//  AddNameViewController.swift
//  PersonRez
//
//  Created by Hồ Sĩ Tuấn on 10/09/2020.
//  Copyright © 2020 Hồ Sĩ Tuấn. All rights reserved.
//

import UIKit
import AVFoundation

class AddNameViewController: UIViewController {
    
    private var generator:AVAssetImageGenerator!
    
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    var videoURL: URL?
    let wrapper = DlibWrapper()

    override func viewDidLoad() {
        super.viewDidLoad()
//        fnet.load()
        if let url = videoURL {
            self.getThumbnailImageFromVideoUrl(url: url) { (thumbImage) in
                self.faceImageView.image = thumbImage
                self.faceImageView.layer.cornerRadius = self.faceImageView.frame.height / 2
                
                ImageFileManager.shared.saveImage(image: thumbImage, name: String(Int(Date().timeIntervalSince1970))+"_face") { url in
                    print("=== url: \(url) ====")
                    print(url)
                    let urlString = UnsafeMutablePointer<CChar>(mutating: (url as NSString).utf8String)!

                    self.wrapper?.executeFaceRecognize(urlString)
                }
                
            }
        }
        hideKeyboardWhenTappedAround()
        
    }
    
    @IBAction func tapDoneButoon(_ sender: UIButton) {
        if textField.text != "" && videoURL != nil && idTextField.text != "" {
            guard let user_id = Int(idTextField.text!) else {
                showDialog(message: "ID is only number!")
                return
            }
//            ProgressHUD.show("Adding...")
            let getFrames = GetFrames()
            print("Your Name is: \(textField.text!)")
//            fb.uploadUser(name: textField.text!, user_id: user_id) {
//                //ProgressHUD.dismiss()
//            }
            
            //saved to local data
            savedUserList.append(textField.text!)
            defaults.set(savedUserList, forKey: SAVED_USERS)
            
            getFrames.getAllFrames(videoURL!, for: textField.text!)
            self.performSegue(withIdentifier: "testClassifierSegue", sender: nil)
        }
        else {
            self.showDialog(message: "Please fill User ID and Name!")
        }
    }
    
    func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ image: UIImage?)->Void)) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            avAssetImageGenerator.appliesPreferredTrackTransform = true
            let thumnailTime = CMTimeMake(value: 2, timescale: 1)
            do {
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                let thumbImage = UIImage(cgImage: cgThumbImage)
                DispatchQueue.main.async {
                    completion(thumbImage)
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
}



