//
//  ViewController.swift
//  DemoAudioEngineOnRTMP
//
//  Created by Takayuki Sei on 2019/05/20.
//  Copyright © 2019 tionlow. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import ReplayKit
import VideoToolbox

class ViewController: UIViewController, RPScreenRecorderDelegate {
    let disposeBag = DisposeBag()
    var recorder: BufferAudioRecorder? = nil
    let broadcaster = RTMPBroadcaster()
    let image = UIImage(named: "testimage")
    let screenRecoder = RPScreenRecorder.shared()
    var timer: Timer? = nil
    @IBOutlet weak var timeLabel: UILabel!
    
    let rtmpURL = "rtmp://10.172.43.169:1935/live"
//    let rtmpURL = "rtmp://localhost:1935/live"
    let rtmpKey = "testdayo"

    override func viewDidLoad() {
        super.viewDidLoad()
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
        recorder = BufferAudioRecorder(outputFormat: outputFormat!, samplingPerSeconds: 10, dataSplitNumber: 5)
        recorder?
            .buffersSignal
            .emit(onNext: { [weak self] (buffer) in
                print("🍌🍌🍌🍌🍌🍌🍌🍌🍌🍌 START 🍌🍌🍌🍌🍌🍌🍌🍌🍌🍌")
                guard let self = self else { return }
                
                let basicDescription = AudioStreamBasicDescription(mSampleRate: 44100,
                                                                   mFormatID: kAudioFormatLinearPCM,
                                                                   mFormatFlags: kLinearPCMFormatFlagIsFloat,
                                                                   mBytesPerPacket: 4,
                                                                   mFramesPerPacket: 1,
                                                                   mBytesPerFrame: 4,
                                                                   mChannelsPerFrame: 1,
                                                                   mBitsPerChannel: 32,
                                                                   mReserved: 0)
                let convertedFloat = buffer.0.audioBufferList.pointee.mBuffers.convertFloatArray()
                var convertedFloatList: [[Float]] = []
                for i in 0 ..< 5 {
                    let range = convertedFloat.count / 5
                    let list = convertedFloat[i * range ..< (i + 1) * range]
                    convertedFloatList.append([Float](list))
                }
                
                let timestamp = CMTime(value: CMTimeValue(Int(AVAudioTime.seconds(forHostTime: mach_absolute_time()) * 1000000000)),
                                       timescale: 1000000000,
                                       flags: .init(rawValue: 3),
                                       epoch: 0)
                for f in convertedFloatList {
                    guard let audioBuffer = AudioFactory(bd: basicDescription).createSampleBufferBy(pcm: f, time: timestamp) else { return }
//                    print("audio: \(audioBuffer)")
//                    print(f)
                    self.broadcaster.appendSampleBuffer(audioBuffer, withType: .audio)
                }

//                guard let audioBuffer = AudioFactory(bd: basicDescription).createSampleBufferBy(pcm: convertedFloat, time: timestamp) else { return }
//                print("audio: \(audioBuffer)")
//                self.broadcaster.appendSampleBuffer(audioBuffer, withType: .audio)
                
//                guard let audioBuffer2 = convertCMSampleBuffer(from: buffer.0, time: buffer.1) else { return }
////                self.broadcaster.appendSampleBuffer(audioBuffer2, withType: .audio)
//                print("audio: \(audioBuffer2)")
//
//
//                guard let audioBuffer3 = CMSampleBuffer.AudioFactory().createSampleBufferBy(pcm: buffer.0.audioBufferList.pointee.mBuffers.convertFloatArray(), asbd: buffer.0.format.streamDescription) else { return }
//                print("audio: \(audioBuffer3)")
//                self.broadcaster.appendSampleBuffer(audioBuffer3, withType: .audio)
                print("🍊🍊🍊🍊🍊🍊🍊🍊🍊🍊🍊 END 🍊🍊🍊🍊🍊🍊🍊🍊🍊🍊🍊")

            }).disposed(by: disposeBag)
        
        broadcaster.stream.videoSettings = [
            "width": 540,
            "height": 960,
            "bitrate": 6 * 160 * 1024,
            "maxKeyFrameIntervalDuration": 4.0,
            "profileLevel": kVTProfileLevel_H264_Baseline_AutoLevel,
            "scalingMode": "Trim"
        ]
        // AAC-LC
        broadcaster.stream.audioSettings = [
            "bitrate": 64 * 1024,
        ]
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            self.timeLabel.text = "\(Date())"
        })
    }
    
    @IBAction func didTouchUpAEStartButton() {
        recorder?.start()
        broadcaster.streamName = rtmpKey
        broadcaster.connect(rtmpURL, arguments: nil)
    }
    
    @IBAction func didTouchUpAEStopButton() {
        broadcaster.close()
        recorder?.stop()
    }
    
    @IBAction func didTouchUpRKStartButton() {
        screenRecoder.isMicrophoneEnabled = true
        screenRecoder.startCapture(handler: { (sampleBuffer, type, error) in
            if let error = error {
                print(error)
                return
            }
            
            switch type {
            case .video:
                self.broadcaster.appendSampleBuffer(sampleBuffer, withType: .video)
            case .audioApp: break
            case .audioMic:
                self.broadcaster.appendSampleBuffer(sampleBuffer, withType: .audio)
            }
        }) { (error) in
            print("start rp \(error)")
        }
        broadcaster.streamName = rtmpKey
        broadcaster.connect(rtmpURL, arguments: nil)
    }
    
    @IBAction func didTouchUpRKStopButton() {
        broadcaster.close()
        screenRecoder.stopCapture { (error) in
            print(error)
        }
    }
    
    @IBAction func didTouchUpAERKStartButton() {
        screenRecoder.startCapture(handler: { (sampleBuffer, type, error) in
            if let error = error {
                print(error)
                return
            }
            
            switch type {
            case .video:
                self.broadcaster.appendSampleBuffer(sampleBuffer, withType: .video)
            case .audioApp, .audioMic: break
            }
        }) { (error) in
            print("start rp \(error)")
        }
        
        recorder?.start()
        broadcaster.streamName = rtmpKey
        broadcaster.connect(rtmpURL, arguments: nil)
    }
    
    @IBAction func didTouchUpAERKStopButton() {
        broadcaster.close()
        recorder?.stop()
        screenRecoder.stopCapture { (error) in
            print(error)
        }
    }
}

