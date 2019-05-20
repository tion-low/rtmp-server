//
//  BufferAudioRecorder.swift
//  DemoAudioEngineOnRTMP
//
//  Created by Takayuki Sei on 2019/05/20.
//  Copyright © 2019 tionlow. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

class BufferAudioRecorder {
    private let audioEngine = AVAudioEngine()
    private let inputFormat: AVAudioFormat!
    private let outputFormat: AVAudioFormat!
    private let converter: AVAudioConverter!

    private let buffers = PublishRelay<(AVAudioPCMBuffer, AVAudioTime)>()
    var buffersSignal: Signal<(AVAudioPCMBuffer, AVAudioTime)> {
        return buffers.asSignal()
    }
    
    private let convertedBuffers = PublishRelay<[Data]>()
    var convertedBuffersSignal: Signal<[Data]> {
        return convertedBuffers.asSignal()
    }

    init(outputFormat: AVAudioFormat, samplingPerSeconds: Int, dataSplitNumber: Int) {
        self.outputFormat = outputFormat
        inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inputFormat, to: outputFormat)

        audioEngine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(Int(inputFormat.sampleRate) / samplingPerSeconds), format: inputFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            self.buffers.accept((buffer, time))

            var error: NSError?
            let pcmBuffer = AVAudioPCMBuffer(pcmFormat: self.outputFormat, frameCapacity: AVAudioFrameCount(self.inputFormat.sampleRate / 10))!
            self.converter.convert(to: pcmBuffer, error: &error, withInputFrom: { (_, outStatus) -> AVAudioBuffer? in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            })

            if let e = error {
                print(e.localizedDescription)
                return
            }

            guard let raw = pcmBuffer.audioBufferList.pointee.mBuffers.mData else { return }
            let data = Data(bytes: raw, count: Int(pcmBuffer.audioBufferList.pointee.mBuffers.mDataByteSize))
            var buffers: [Data] = []
            let frameSize = data.count / dataSplitNumber
            for i in 0 ..< (data.count / frameSize) {
                let d = data.subdata(in: i * frameSize..<(i * frameSize) + frameSize)
                buffers.append(d)
            }

            self.convertedBuffers.accept(buffers)
        }

        audioEngine.prepare()
    }

    func start() {
        do {
            try audioEngine.start()
        } catch let error {
            print(error)
        }
    }

    func stop() {
        audioEngine.stop()
    }
}
