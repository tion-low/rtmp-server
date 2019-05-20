//
//  SampleBufferCreator.swift
//  DemoAudioEngineOnRTMP
//
//  Created by Takayuki Sei on 2019/05/20.
//  Copyright © 2019 tionlow. All rights reserved.
//

import Foundation
import AVFoundation

public class AudioFactory {
    private var formatDescription: CMAudioFormatDescription!
    
    init(bd: AudioStreamBasicDescription) {
        var basicDescription = bd
        var tmpDescription: CMAudioFormatDescription?
        let status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                    asbd: &basicDescription,
                                                    layoutSize: 0,
                                                    layout: nil,
                                                    magicCookieSize: 0,
                                                    magicCookie: nil,
                                                    extensions: nil,
                                                    formatDescriptionOut: &tmpDescription)
        if status != noErr {
            print("failed create cmsamplebuffer audio factory@1")
        }
        guard let outDescription = tmpDescription else {
            print("failed create cmsamplebuffer audio factory@2")
            return
        }
        formatDescription = outDescription
    }
    
    public func createSampleBufferBy<T>(pcm: [T]) -> CMSampleBuffer? {
        var blockBuffer: CMBlockBuffer?
        _ = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                               memoryBlock: UnsafeMutableRawPointer(mutating: pcm),
                                               blockLength: pcm.count * MemoryLayout<T>.stride,
                                               blockAllocator: kCFAllocatorNull,
                                               customBlockSource: nil,
                                               offsetToData: 0,
                                               dataLength: pcm.count * MemoryLayout<T>.stride,
                                               flags: 0,
                                               blockBufferOut: &blockBuffer)
        var sampleBuffer: CMSampleBuffer?
        let timestamp = CMTime(value: CMTimeValue(Int(AVAudioTime.seconds(forHostTime: mach_absolute_time()))),
                               timescale: 1000000000,
                               flags: .init(rawValue: 3),
                               epoch: 0)
        _ = CMAudioSampleBufferCreateWithPacketDescriptions(allocator: kCFAllocatorDefault,
                                                            dataBuffer: blockBuffer,
                                                            dataReady: true,
                                                            makeDataReadyCallback: nil,
                                                            refcon: nil,
                                                            formatDescription: formatDescription,
                                                            sampleCount: pcm.count,
                                                            presentationTimeStamp: timestamp,
                                                            packetDescriptions: nil,
                                                            sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }
    
    public func createSampleBufferBy(pcm: [Float], asbd: UnsafePointer<AudioStreamBasicDescription>) -> CMSampleBuffer? {
        var formatDescription: CMFormatDescription!
        let status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
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
        
        var blockBuffer: CMBlockBuffer?
        _ = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                               memoryBlock: UnsafeMutableRawPointer(mutating: pcm),
                                               blockLength: pcm.count * MemoryLayout<Float>.stride,
                                               blockAllocator: kCFAllocatorNull,
                                               customBlockSource: nil,
                                               offsetToData: 0,
                                               dataLength: pcm.count * MemoryLayout<Float>.stride,
                                               flags: 0,
                                               blockBufferOut: &blockBuffer)
        var sampleBuffer: CMSampleBuffer?
        let timestamp = CMTime(value: CMTimeValue(Int(Date().timeIntervalSince1970 * 3000)),
                               timescale: 3000,
                               flags: .init(rawValue: 3),
                               epoch: 0)
        _ = CMAudioSampleBufferCreateWithPacketDescriptions(allocator: kCFAllocatorDefault,
                                                            dataBuffer: blockBuffer,
                                                            dataReady: true,
                                                            makeDataReadyCallback: nil,
                                                            refcon: nil,
                                                            formatDescription: formatDescription,
                                                            sampleCount: pcm.count,
                                                            presentationTimeStamp: timestamp,
                                                            packetDescriptions: nil,
                                                            sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }
}

extension AudioBuffer {
    public func convertFloatArray() -> [Float] {
        if let mdata: UnsafeMutableRawPointer = self.mData {
            let usmp: UnsafeMutablePointer<Float> = mdata.assumingMemoryBound(to: Float.self)
            let usp = UnsafeBufferPointer(start: usmp, count: Int(self.mDataByteSize) / MemoryLayout<Float>.size)
            return Array(usp)
        } else {
            return [Float]()
        }
    }
}
