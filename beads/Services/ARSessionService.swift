// MARK: - 檔案說明
/// ARSessionService.swift
/// AR 會話服務 - 管理 AR 權限狀態與裝置支援檢測
/// 模組：Services

import Foundation
import AVFoundation
import Observation

#if os(iOS)
import ARKit
#endif

/// AR 相機權限狀態列舉
enum ARPermissionStatus: String {
    case notDetermined
    case authorized
    case denied
}

/// AR 會話服務
/// 負責管理相機權限請求與 AR 裝置支援檢測
@Observable
final class ARSessionService {
    /// 目前的相機權限狀態
    var permissionStatus: ARPermissionStatus = .notDetermined

    /// 裝置是否支援 AR 功能
    var isARSupported: Bool {
        #if os(iOS)
        return ARWorldTrackingConfiguration.isSupported
        #else
        return false
        #endif
    }

    init() {
        syncPermissionStatus()
    }

    /// 請求相機權限
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionStatus = granted ? .authorized : .denied
                completion(granted)
            }
        }
    }

    /// 同步系統目前的相機權限狀態
    private func syncPermissionStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionStatus = .authorized
        case .denied, .restricted:
            permissionStatus = .denied
        case .notDetermined:
            permissionStatus = .notDetermined
        @unknown default:
            permissionStatus = .notDetermined
        }
    }
}
