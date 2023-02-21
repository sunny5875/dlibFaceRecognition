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
    var videoImage: UIImage?
    
    let wrapper = DlibWrapper()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.faceImageView.layer.cornerRadius = self.faceImageView.frame.height / 2
        self.faceImageView.image = videoImage
//        if let url = videoURL {
//            self.getThumbnailImageFromVideoUrl(url: url) { (thumbImage) in
//                self.faceImageView.image = thumbImage
//                self.faceImageView.layer.cornerRadius = self.faceImageView.frame.height / 2
//
//                ImageFileManager.shared.saveImage(image: thumbImage, name: "face.jpeg") { url in
//                    print("=== url: \(url) ====")
//                    print(url)
//                    let urlString = UnsafeMutablePointer<CChar>(mutating: (url as NSString).utf8String)!
//
//                    self.wrapper?.executeFaceRecognize(urlString)
//                }
//
//            }
//        }
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
    
    
}



