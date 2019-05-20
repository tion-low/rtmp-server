//
//  BufferAudioRecorder.swift
//  vLive-viewer-ios
//
//  Created by Takayuki Sei on 2019/04/16.
//  Copyright © 2019 GREE, Inc. All rights reserved.
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

    private let buffers = PublishRelay<[Data]>()
    var buffersSignal: Signal<[Data]> {
        return buffers.asSignal()
    }

    init(outputFormat: AVAudioFormat, samplingPerSeconds: Int, dataSplitNumber: Int) {
        self.outputFormat = outputFormat
        VliveAppState.shared.audioEnvironment.setState(state: .voiceChat)
        inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inputFormat, to: outputFormat)

        audioEngine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(Int(inputFormat.sampleRate) / samplingPerSeconds), format: inputFormat) { [weak self] (buffer, _) in
            guard let s = self else { return  }

            var error: NSError?
            let pcmBuffer = AVAudioPCMBuffer(pcmFormat: s.outputFormat, frameCapacity: AVAudioFrameCount(s.inputFormat.sampleRate / 10))!
            s.converter.convert(to: pcmBuffer, error: &error, withInputFrom: { (_, outStatus) -> AVAudioBuffer? in
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

            s.buffers.accept(buffers)
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
