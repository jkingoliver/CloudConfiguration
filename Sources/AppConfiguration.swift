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

import Configuration
import CloudFoundryEnv
import Foundation
import HeliumLogger
import LoggerAPI


public class AppConfiguration {

    let mapManager = ConfigurationManager()

    let mappingFile = "mapping.json"
    let mappingFilePath = "../../config/mapping.json"

    public init () {

        HeliumLogger.use(LoggerMessageType.info)

        let filePath = URL(fileURLWithPath: #file).appendingPathComponent(mappingFilePath).standardized

        mapManager.load(url: filePath)
        mapManager.load(file: mappingFile, relativeFrom: .pwd)

    }

    public func getCredentials(name: String) -> [String:Any]? {

        HeliumLogger.use(LoggerMessageType.info)

        guard let searchPatterns = mapManager["\(name):searchPatterns"] as? [String] else {
            Log.error("*** NO SEARCH PATTERN FOUND")
            return nil
        }

        for pattern in searchPatterns {

            //Possible patterns:
            // "file:"
            // "file:/local-development-credentials.json"
            // "file:/local-development-credentials.json:my-cloudant-credentials"
            var arr = pattern.components(separatedBy: ":")

            let key = arr.removeFirst()
            let value = arr.removeFirst()

            switch (key) {
            case "cloudfoundry":    // CloudFoundry/swift-cfenv
                if let credentials = getCloudFoundryCreds(name: value) {
                    return credentials
                }
                break
            case "env":             // Kubernetes
                if let credentials = getKubeCreds(name: value) {
                    return credentials
                }
                break
            case "file":            // File- local or in cloud foundry
                let instance = (arr.count > 0) ? arr[0] : name

                if let credentials = getLocalCreds(instance: instance, path: value) {
                    return credentials
                }
                break
            default:
                return nil
            }

        }

        return nil
    }

    private func getCloudFoundryCreds(name: String) -> [String:Any]? {

        let cfManager = ConfigurationManager()
        cfManager.load(.environmentVariables)

        guard let credentials = cfManager.getServiceCreds(spec: name) else {
            print("CLOUD FOUNDRY FAIL")
            return nil
        }

        return credentials
    }

    private func getKubeCreds(name: String) -> [String:Any]? {

        let kubeManager = ConfigurationManager()
        kubeManager.load(.environmentVariables)

        guard let credentials = kubeManager["\(name)"] as? [String: Any] else {
            Log.info("*** KUBE FAIL *** ")
            return nil
        }

        return credentials
    }

    private func getLocalCreds(instance: String, path: String) -> [String:Any]? {

        let fileManager = ConfigurationManager()

        // Load local file
        let filePath = URL(fileURLWithPath: #file).appendingPathComponent(path).standardized
        fileManager.load(url: filePath)

        // Load file in cloud foundry-- extract filename from path
        if let fileName = path.components(separatedBy: "/").last {
            fileManager.load(file: fileName, relativeFrom: .pwd)
        }
        
        guard let credentials = fileManager.getServiceCreds(spec: instance) else {
            print("LOCAL CREDS FAIL")
            return nil
        }
        
        return credentials
    }
}

