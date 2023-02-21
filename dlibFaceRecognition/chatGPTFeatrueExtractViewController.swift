//
//  chatGPTFeatrueExtractViewController.swift
//  dlibFaceRecognition
//
//  Created by 현수빈 on 2023/02/20.
//
import UIKit
import Vision

class chatGPTFeatrueExtractViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "face") // 얼굴이 있는 이미지
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        guard let ciImage = CIImage(image: image!) else { return }
        
        // 얼굴인식 요청 생성
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: handleFaceDetection)
        
        // 이미지 처리 요청
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try? requestHandler.perform([faceDetectionRequest])
    }
    
    func handleFaceDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else { return }
        for observation in observations {
            // 얼굴 영역 추출
            let boundingBox = observation.boundingBox
            
            // 얼굴 특징 추출
            let landmarks = observation.landmarks
            let faceContour = landmarks?.faceContour?.normalizedPoints
            let leftEyebrow = landmarks?.leftEyebrow?.normalizedPoints
            let rightEyebrow = landmarks?.rightEyebrow?.normalizedPoints
            let nose = landmarks?.nose?.normalizedPoints
            let noseCrest = landmarks?.noseCrest?.normalizedPoints
            let medianLine = landmarks?.medianLine?.normalizedPoints
            let outerLips = landmarks?.outerLips?.normalizedPoints
            let innerLips = landmarks?.innerLips?.normalizedPoints
            
            // 추출한 특징을 합칩니다.
            var featureVector: [CGPoint] = []
            featureVector += faceContour ?? []
            featureVector += leftEyebrow ?? []
            featureVector += rightEyebrow ?? []
            featureVector += nose ?? []
            featureVector += noseCrest ?? []
            featureVector += medianLine ?? []
            featureVector += outerLips ?? []
            featureVector += innerLips ?? []
            
            // featureVector 배열에는 128개의 float 값이 들어 있습니다.
            print(featureVector)
        }
    }
}
