//
//  AudioEnvironment.swift
//  DemoAudioEngineOnRTMP
//
//  Created by Takayuki Sei on 2019/05/20.
//  Copyright © 2019 tionlow. All rights reserved.
//

import Foundation
import AVFoundation

struct AudioEnvironment {
    func setState(state: VLiveAudioState) {
        let config = state.config()
        do {
            try AVAudioSession.sharedInstance().setCategory(config.category, mode: config.mode, options: config.options)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error)
        }
    }
}

enum VLiveAudioState {
    case `default`
    case playInBackground
    case voiceChat

    func config() -> AudioSessionConifg {
        switch self {
        case .default:
            return AudioSessionConifg(category: .soloAmbient, mode: .default, options: [])
        case .playInBackground:
            return AudioSessionConifg(category: .playback, mode: .moviePlayback, options: [.mixWithOthers])
        case .voiceChat:
            return AudioSessionConifg(category: .playAndRecord, mode: .voiceChat, options: [.allowBluetoothA2DP])
        }
    }
}

struct AudioSessionConifg {
    let category: AVAudioSession.Category
    let mode: AVAudioSession.Mode
    let options: AVAudioSession.CategoryOptions
}
