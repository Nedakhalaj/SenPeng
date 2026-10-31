import Foundation
import Testing
@testable import Senpeng

/// Checks the requests sent to SL's Transport API.
@Suite("SL Transport API")
struct SLTransportAPITests {

    @Test("The stop list request goes to SL's sites endpoint without platform details")
    func sitesRequest() {
        let request = SLTransportAPI.sites().makeRequest()

        #expect(request.url?.absoluteString == "https://transport.integration.sl.se/v1/sites?expand=false")
    }
}
