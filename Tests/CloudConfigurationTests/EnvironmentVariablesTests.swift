/*
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import XCTest
import Configuration
@testable import CloudConfiguration

class EnvironmentVariablesTests: XCTestCase {

    static var allTests : [(String, (EnvironmentVariablesTests) -> () throws -> Void)] {
        return [
            ("testGetCredentials", testGetCredentials),
        ]
    }

    func testGetCredentials() {

        let manager = AppConfiguration()

        // Load test mapping.json file
        manager.loadMappingTestConfigs(path: "Tests/ConfigTests/mapping.json")

        let jsonString = "{\"name\":\"21a084f4-4eb3-4de4-9834-33bdc7be5df9/d2a85740-da7a-4615-aabf-5bdc35c63618\",\"password\":\"alertnotification-pwd\",\"url\":\"https://ibmnotifybm.mybluemix.net/api/alerts/v1\",\"swaggerui\":\"https://ibmnotifybm.mybluemix.net/docs/alerts/v1\"}"

        // TODO docker compose -- test on linux -- make sure it's invoking `swift test`
        // Set env var
        XCTAssertEqual(setenv("KUBE_ENV", jsonString, 1), 0)

        guard let credentials =  manager.getAlertNotificationCredentials(name: "AlertNotificationEVKey") else {
            XCTFail("Could not load Alert Notification service credentials.")
            return
        }

        // TODO convert jsonString -> json, then test against json.url etc

        XCTAssertEqual(credentials.url, "https://ibmnotifybm.mybluemix.net/api/alerts/v1", "Alert Notification Service URL should match.")
        XCTAssertEqual(credentials.id, "21a084f4-4eb3-4de4-9834-33bdc7be5df9/d2a85740-da7a-4615-aabf-5bdc35c63618", "Alert Notification Service ID should match.")
        XCTAssertEqual(credentials.password, "alertnotification-pwd", "Alert Notification Service password should match.")
        XCTAssertEqual(credentials.swaggerUI, "https://ibmnotifybm.mybluemix.net/docs/alerts/v1", "Alert Notification Service swaggerUI should match.")

        // Unset env var
        XCTAssertEqual(unsetenv("KUBE_ENV"), 0)
    }
}

