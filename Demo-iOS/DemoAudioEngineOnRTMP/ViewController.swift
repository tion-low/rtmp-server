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
    
    let rtmpURL = "rtmp://10.172.42.177:1935/live"
    let rtmpKey = "testdayo"

    override func viewDidLoad() {
        super.viewDidLoad()
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 48000, channels: 1, interleaved: false)
        recorder = BufferAudioRecorder(outputFormat: outputFormat!, samplingPerSeconds: 10, dataSplitNumber: 5)
        recorder?
            .buffersSignal
            .emit(onNext: { [weak self] (buffer) in
                print("🍌🍌🍌🍌🍌🍌🍌🍌🍌🍌 START 🍌🍌🍌🍌🍌🍌🍌🍌🍌🍌")
                
                guard let self = self, let audioBuffer = convertCMSampleBuffer(from: buffer.0, time: buffer.1) else { return }
                self.broadcaster.appendSampleBuffer(audioBuffer, withType: .audio)
                print("audio: \(audioBuffer)")
                
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
            "bitrate": 64 * 1024
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
}

func convertCMSampleBuffer(from pcmBuffer: AVAudioPCMBuffer, time: AVAudioTime) -> CMSampleBuffer? {
    let bufferList = pcmBuffer.audioBufferList
    let asbd = pcmBuffer.format.streamDescription
    
    var sampleBuffer: CMSampleBuffer!
    var formatDescription: CMFormatDescription!

    var status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                            asbd: asbd,
                                            layoutSize: 0,
                                            layout: nil,
                                            magicCookieSize: 0,
                                            magicCookie: nil,
                                            extensions: nil,
                                            formatDescriptionOut: &formatDescription)
    guard status == kCMBlockBufferNoErr else {
        return nil
    }
    var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: CMTimeScale(asbd.pointee.mSampleRate)),
                                    presentationTimeStamp: CMTime(seconds: AVAudioTime.seconds(forHostTime: time.hostTime), preferredTimescale: 1000000000),
                                    decodeTimeStamp: CMTime.invalid)
    
    status = CMSampleBufferCreate(allocator: kCFAllocatorDefault,
                                  dataBuffer: nil,
                                  dataReady: false,
                                  makeDataReadyCallback: nil,
                                  refcon: nil,
                                  formatDescription: formatDescription,
                                  sampleCount: CMItemCount(pcmBuffer.frameLength),
                                  sampleTimingEntryCount: 1,
                                  sampleTimingArray: &timing,
                                  sampleSizeEntryCount: 0,
                                  sampleSizeArray: nil,
                                  sampleBufferOut: &sampleBuffer)
    guard status == kCMBlockBufferNoErr else {
        return nil
    }
    status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer,
                                                            blockBufferAllocator: kCFAllocatorDefault,
                                                            blockBufferMemoryAllocator: kCFAllocatorDefault,
                                                            flags: 0,
                                                            bufferList: bufferList)
    guard status == kCMBlockBufferNoErr else {
        return nil
    }
    
    return sampleBuffer
}
