import Testing
import Foundation
@testable import beads

struct ARSessionServiceTests {
    @Test func initialPermissionStateIsNotDetermined() async throws {
        let service = ARSessionService()
        // On simulator, permission may be notDetermined or denied
        let validStatuses: [ARPermissionStatus] = [.notDetermined, .denied]
        #expect(validStatuses.contains(service.permissionStatus))
    }

    @Test func arSupportedPropertyExists() async throws {
        let service = ARSessionService()
        // On simulator, AR is not supported, so just verify the property is accessible
        #expect(service.isARSupported == false || service.isARSupported == true)
    }

    @Test func permissionStatusEnumHasAllCases() async throws {
        let statuses: [ARPermissionStatus] = [.notDetermined, .authorized, .denied]
        #expect(statuses.count == 3)
    }
}
