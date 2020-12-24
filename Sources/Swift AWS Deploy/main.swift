import ArgumentParser

struct AWSSwift: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for deploying an AWS stack with Swift Lambda functions",
        subcommands: [Deploy.self],
        defaultSubcommand: Deploy.self
    )
}

AWSSwift.main()
