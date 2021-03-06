//  Copyright 2018, Oath Inc.
//  Licensed under the terms of the MIT License. See LICENSE.md file in project root for terms.
import Foundation

public enum OpenMeasurement {
    case disabled
    case inactive
    case readyForLoad([Ad.VASTModel.AdVerification])
    case loading
    case active(AdEvents, VideoEvents)
    case finished(AdEvents, VideoEvents)
    case failed(Error)
    
    public var isFailed: Bool {
        guard case .failed = self else { return false }
        return true
    }
    public var isActive: Bool {
        guard case .active = self else { return false }
        return true
    }
    public var isFinished: Bool {
        guard case .finished = self else { return false }
        return true
    }
}

func reduce(state: OpenMeasurement, action: Action) -> OpenMeasurement {
    switch action {
    case let action as VRMCore.SelectFinalResult where state != .disabled:
        let inline = action.inlineVAST
        guard inline.adVerifications.isEmpty == false,
              inline.mp4MediaFiles.isEmpty == false else {
            return .inactive
        }
        return .readyForLoad(inline.adVerifications)
        
    case is ShowMP4Ad:
        return .loading
        
    case let action as OpenMeasurementActivated where state != .disabled:
        return .active(action.adEvents, action.videoEvents)
        
    case is OpenMeasurementDeactivated where state != .disabled:
        return .inactive
        
    case is DropAd,
         is ShowContent,
         is SkipAd,
         is AdPlaybackFailed,
         is SelectVideoAtIdx,
         is MP4AdStartTimeout,
         is AdMaxShowTimeout:
        guard case .active(let adEvents, let videoEvents) = state else { return state }
        return .finished(adEvents, videoEvents)
        
    case let action as OpenMeasurementConfigurationFailed:
        guard case .loading = state else { return state }
        return .failed(action.error)
        
    default: return state
    }
}

extension OpenMeasurement: Equatable {
    public static func == (lhs: OpenMeasurement, rhs: OpenMeasurement) -> Bool {
        switch (lhs, rhs) {
        case (.disabled, .disabled): return true
        case (.inactive, .inactive): return true
        case (.active, .active): return true
        case (.failed, .failed): return true
        case (.loading, .loading): return true
        case let (.readyForLoad(left), .readyForLoad(right)):
            return left == right
        default: return false
        }
    }
}
