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


class RecordVideoViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
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
//        saveFaceRecognition(title: "shape_predictor_5_face_landmarks")
//        saveFaceRecognition(title: "dlib_face_recognition_resnet_model_v1")
       
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
    
//    func saveFaceRecognition(title: String) {
//        let data: Data
//
//        do {
//            // xcode 내 파일 읽기
//            guard let path = Bundle.main.path(forResource: title, ofType: ".dat") else {return}
//            print("xcode 내 파일 path: ", path)
//            let fromUrl = URL(string : "file://"+path)
//            data = try Data(contentsOf: fromUrl!)
//
//            let str = try String(contentsOf: fromUrl!)
//            print(str)
//
//            // 폰에 저장
//            let fileManager = FileManager.default
//            let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//            print(directoryURL.absoluteString)
//            //        let directoryURL = documentsURL.appendingPathComponent("Test_Folder")
////            try fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: false, attributes: nil)
//            let toPath = directoryURL.appendingPathComponent(title+".dat")
//            try data.write(to: toPath)
//            wrapper?.loadData(fromPath: title)//toPath.absoluteString)
//        } catch let e {
//            print(e.localizedDescription)
//        }
//    }
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
            self.view.makeToastActivity(.center)
            DispatchQueue.main.async {
                self.featureExtract()
//                self.performSegue(withIdentifier: "openFillName", sender: nil)
            }
           
        }
        
    }
    
    private func featureExtract() {
        if let url = outputVideoUrl {
            self.getThumbnailImageFromVideoUrl(url: url) { (list) in
//                self.videoImage = list.first as! UIImage
                let totalStart = DispatchTime.now()
                for item in list{
                    ImageFileManager.shared.saveImage(image: item, name: "face.jpeg") { url in
                        print("=== url: \(url) ====")
                        print(url)
                        let urlString = UnsafeMutablePointer<CChar>(mutating: (url as NSString).utf8String)!

                       let result = self.wrapper?.executeFaceRecognize()
                        
                        if let swiftArray = (result ?? []) as NSArray as? [String] {
                            // Use swiftArray here
                            print("❤️", swiftArray)
                            self.view.hideAllToasts()
                            self.view.makeToast("feature extract: \(swiftArray)")
                        }
                        
                    }
                }
                
                let totalEnd = DispatchTime.now()
                        print("total 시간: \(totalEnd.uptimeNanoseconds - totalStart.uptimeNanoseconds)")
                self.view.hideAllToasts()
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
    
    
    func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ image: [UIImage?])->Void)) {
        var list: [UIImage?] = []
        
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            avAssetImageGenerator.appliesPreferredTrackTransform = true
           
            do {
                let thumnailTime = CMTimeMake(value: 1, timescale: 2)
                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                list.append(UIImage(cgImage: cgThumbImage))
                
                let thumnailTime1 = CMTimeMake(value: 3, timescale: 2)
                let cgThumbImage1 = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                list.append(UIImage(cgImage: cgThumbImage1))
                
                let thumnailTime2 = CMTimeMake(value: 3, timescale: 2)
                let cgThumbImage2 = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                list.append(UIImage(cgImage: cgThumbImage2))
                
                DispatchQueue.main.async {
                    completion(list)
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion([])
                }
            }
            
        }
    }
}
