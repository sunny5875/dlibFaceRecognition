//
//  RecordVideoViewController.swift
//  PersonRez
//
//  Created by Hồ Sĩ Tuấn on 09/09/2020.
//  Copyright © 2020 Hồ Sĩ Tuấn. All rights reserved.
//

import UIKit
import AVFoundation
import Toast
import Vision


class RecordVideoViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var mergeImageView: UIImageView!
    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var videoView: VideoView!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var movieOutput = AVCaptureMovieFileOutput()
    
    var timeRecord = 3
    var timer = Timer()
    var outputVideoUrl: URL?
    let wrapper = DlibWrapper()
    var videoImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        else {
            print("Unable to access front camera!")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize front camera:  \(error.localizedDescription)")
        }
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openFillName" {
            let vc = segue.destination as! AddNameViewController
            vc.videoURL = outputVideoUrl
            vc.videoImage = videoImage
           
        }
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) != nil else {
            showDialog(message: "Not supported in simulator!")
            return
        }
        if startButton.titleLabel?.text == "Start" {
            desLabel.text = "Move your head slowly!"
            startButton.isEnabled = false
            captureSession.addOutput(movieOutput)
            let paths = documentDirectory.appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: paths)
            movieOutput.startRecording(to: paths, recordingDelegate: self)
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }
        else {
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.view.makeToastActivity(.center)
            }
            self.featureExtract()
//                self.performSegue(withIdentifier: "openFillName", sender: nil)
           
        }
        
    }
    
    private func featureExtract() {
            if let url = self.outputVideoUrl {
                self.getThumbnailImageFromVideoUrl(url: url) { (image) in
                    guard let image = image else {return}
                    ImageFileManager.shared.saveImage(image: image, name: "face.jpeg") { url in
                        print("=== url: \(url) ====")
                        print(url)
                        let urlString = UnsafeMutablePointer<CChar>(mutating: (url as NSString).utf8String)!
                        
                        DispatchQueue.global().async {
                            let eachStart = DispatchTime.now()
                            let result = self.wrapper?.executeFaceRecognize()
                            let endStart = DispatchTime.now()
                            print("total 시간: \(endStart.uptimeNanoseconds - eachStart.uptimeNanoseconds)")
                            
                            if let swiftArray = (result ?? []) as NSArray as? [String] {
                                print("❤️", swiftArray)
                                DispatchQueue.main.async {
                                    self.view.hideAllToasts()
                                    self.view.makeToast("feature extract result count: \(swiftArray.count)")
                                }
                            }
                        }
                        
                    }
                }
            }
    }
    
    @objc func timerAction() {
        timeRecord -= 1
        startButton.setTitle("\(timeRecord) seconds remaining!", for: .disabled)
        if timeRecord == 0 {
            self.movieOutput.stopRecording()
            timer.invalidate()
            startButton.isEnabled = true
            timeRecord = 3
            startButton.setTitle("Done", for: .normal)
        }
    }
    
    func setupLivePreview() {
        videoView.layer.cornerRadius = 150
        videoView.layer.masksToBounds = true
        videoView.layer.borderWidth = 1
        videoView.layer.borderColor = UIColor.green.cgColor
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = videoView.layer.bounds
        
        videoPreviewLayer.connection?.videoOrientation = .portrait
        videoView.layer.insertSublayer(videoPreviewLayer, at: 0)
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.videoView.bounds
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("FINISHED RECORD VIDEO")
        if error == nil {
            outputVideoUrl = outputFileURL
        }
    }
    
    
    func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ image: UIImage?)->Void)) {
         
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            avAssetImageGenerator.appliesPreferredTrackTransform = true
           
            do {
                let thumnailTime = CMTimeMake(value: 1, timescale: 2)
                let cgThumbImage = self.cropImage(image: UIImage(cgImage: try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)))
               

                let thumnailTime1 = CMTimeMake(value: 3, timescale: 2)
                let cgThumbImage1 = self.cropImage(image:UIImage(cgImage: try avAssetImageGenerator.copyCGImage(at: thumnailTime1, actualTime: nil)))
              
                let thumnailTime2 = CMTimeMake(value: 3, timescale: 2)
                let cgThumbImage2 = self.cropImage(image:UIImage(cgImage: try avAssetImageGenerator.copyCGImage(at: thumnailTime2, actualTime: nil)))
               
                let size = CGSizeMake(cgThumbImage.size.width + cgThumbImage1.size.width + cgThumbImage2.size.width, cgThumbImage.size.height)

               UIGraphicsBeginImageContext(size)
                cgThumbImage.draw(in: CGRectMake(0,
                                                   0,
                                                   cgThumbImage.size.width,
                                                   cgThumbImage.size.height
                                                          ))
                cgThumbImage1.draw(in: CGRectMake(cgThumbImage.size.width,
                                                    0,
                                                    cgThumbImage1.size.width,
                                                    cgThumbImage1.size.height
                                                           ))
                cgThumbImage2.draw(in: CGRectMake(cgThumbImage.size.width + cgThumbImage1.size.width,
                                                    0,
                                                    cgThumbImage2.size.width,
                                                    cgThumbImage2.size.height
                                                   ))
               let finalImage = UIGraphicsGetImageFromCurrentImageContext()
               UIGraphicsEndImageContext()
                DispatchQueue.main.async {
                    self.mergeImageView.image = finalImage
                }
                completion(finalImage)
               
            } catch {
                print(error.localizedDescription)
                completion(nil)
            }
            
        }
    }
    
    func cropImage(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return UIImage()}
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let faceDetectionRequest = VNDetectFaceRectanglesRequest()
        try? requestHandler.perform([faceDetectionRequest])
        guard let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation] else { return UIImage()}

        for observation in faceDetectionResults {
            let boundingBox = observation.boundingBox
            let imageWidth = CGFloat(cgImage.width)
            let imageHeight = CGFloat(cgImage.height)
            
            // 이미지 좌표계를 Vision 좌표계로 변환합니다.
            let rect = CGRect(x: boundingBox.origin.x * imageWidth,
                              y: (1 - boundingBox.origin.y - boundingBox.size.height) * imageHeight,
                              width: boundingBox.size.width * imageWidth,
                              height: boundingBox.size.height * imageHeight)
            
            // crop된 이미지를 생성합니다.
            if let croppedImage = cgImage.cropping(to: rect) {
                let croppedUIImage = UIImage(cgImage: croppedImage)
                return croppedUIImage
            }
        }
        return UIImage()
    }
}
