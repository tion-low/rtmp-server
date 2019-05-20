//
//  AudioEnvironment.swift
//  vLive-viewer-ios
//
//  Created by Takayuki Sei on 2019/04/10.
//  Copyright © 2019 GREE, Inc. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

struct AudioEnvironment {
    private let sessionState = BehaviorRelay<VLiveAudioState>(value: VLiveAudioState.default)
    var sessoinStateDriver: Driver<VLiveAudioState> {
        return sessionState.asDriver()
    }
    private let disposeBag = DisposeBag()

    func setState(state: VLiveAudioState) {
        let config = state.config()
        do {
            try AVAudioSession.sharedInstance().setCategory(config.category, mode: config.mode, options: config.options)
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setPreferredSampleRate(48000.0)
            sessionState.accept(state)
        } catch let error {
            // TODO: エラーハンドリング
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
