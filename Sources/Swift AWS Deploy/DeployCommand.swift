//
//  DeployCommand.swift
//  
//
//  Created by Davis Allie on 24/12/20.
//

import ArgumentParser
import Foundation

struct Deploy: ParsableCommand {
    
    @Option var configFile: String?
    
    @Argument var environment: String
    
    func run() throws {
        let filePath = FileManager.default.currentDirectoryPath + "/Deployment/" + (configFile ?? "DeployConfig.json")
        print(filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("Could not find deployment configuration")
            return
        }
        
        let configUrl = URL(fileURLWithPath: filePath)
        let configData = try Data(contentsOf: configUrl)
        let configuration = try JSONDecoder().decode(Configuration.self, from: configData)
        
        guard configuration.allowedEnvironments.contains(environment) else {
            print("Invalid environment specified")
            return
        }
        
        for target in configuration.buildTargets {
            print("Compiling \(target)")
            let compile = shell("Deployment/docker-build.sh", target)
            if compile != 0 {
                return
            }
        }
        
        for target in configuration.buildTargets {
            print("Packaging \(target)")
            
            let zip: Int32
            if let customPackageScript = configuration.customPackageScripts?[target] {
                zip = shell("Deployment/docker-package.sh", target, customPackageScript)
            } else {
                zip = shell("Deployment/docker-package.sh", target, "package.sh")
            }

            if zip != 0 {
                return
            }
        }
        
        let upload = shell("aws cloudformation package --template-file Deployment/\(configuration.cloudFormationConfigFile) --s3-bucket \(configuration.lambdaSourceS3Bucket) --s3-prefix \(environment) --output-template-file Deployment/aws_packaged.json --use-json".components(separatedBy: " "))
        guard upload == 0 else {
            print("Upload error")
            return
        }
        
        let combinedParameterOverrides = (configuration.cloudFormationParameterOverrides ?? [:]).map({ "\($0.key)=\($0.value)" }).joined(separator: " ")
        
        let deploy = shell("aws cloudformation deploy --template-file Deployment/aws_packaged.json --stack-name \(configuration.stackPrefix)-\(environment) --parameter-overrides EnvironmentName=\(environment) \(combinedParameterOverrides) --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM".components(separatedBy: " "))
        
        if deploy != 0 {
            shell("aws cloudformation describe-stack-events --stack-name \(configuration.stackPrefix)-\(environment)".components(separatedBy: " "))
            return
        }
    }
    
}

