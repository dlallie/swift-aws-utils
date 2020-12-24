//
//  Configuration.swift
//  
//
//  Created by Davis Allie on 24/12/20.
//

import Foundation

struct Configuration: Codable {
    
    var stackPrefix: String
    var allowedEnvironments: [String]
    var buildTargets: [String]
    var customPackageScripts: [String: String]?
    var lambdaSourceS3Bucket: String
    var cloudFormationConfigFile: String
    var cloudFormationParameterOverrides: [String: String]?
    
}
