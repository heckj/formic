import ArgumentParser
import Formic
import Foundation
import Logging

typealias Host = Formic.Host

// example:
// swift run updateExample -v 172.174.57.17 /Users/heckj/.ssh/bastion_id_ed25519

@main
struct configureBastion: AsyncParsableCommand {
    @Option(name: .shortAndLong, help: "The user to connect as") var user: String = "docker-user"
    @Option(name: .shortAndLong, help: "The port to connect through") var port: Int = 22
    @Argument(help: "the hostname or IP address of the host to update") var hostname: String
    @Argument(help: "The path to the private SSH key to copy into bastion") var privateKeyLocation: String
    @Flag(name: .shortAndLong, help: "Run in verbose mode") var verbose: Bool = false

    mutating func run() async throws {
        var logger = Logger(label: "updateExample")
        logger.logLevel = verbose ? .trace : .info
        logger.info("Starting update for \(hostname) as \(user) on port \(port)")

        let engine = Engine(logger: logger)
        // per https://wiki.debian.org/Multistrap/Environment
        let debUnattended = ["DEBIAN_FRONTEND": "noninteractive", "DEBCONF_NONINTERACTIVE_SEEN": "true"]

        guard let hostAddress = Host.NetworkAddress(hostname) else {
            fatalError("Unable to parse the provided host address: \(hostname)")
        }

        let keyName = URL(fileURLWithPath: privateKeyLocation).lastPathComponent
        let bastionHost: Host = try Host(hostAddress, sshPort: port, sshUser: user, sshIdentityFile: privateKeyLocation)
        let verbosity: Verbosity = verbose ? .debug(emoji: true) : .normal(emoji: true)

        try await engine.run(
            host: bastionHost, displayProgress: true, verbosity: verbosity,
            commands: [
                SSHCommand("uname -a"),  // uses CitadelSSH
                SSHCommand("ls -altr"),

                ShellCommand("mkdir -p ~/.ssh"),  // uses Process and forked 'ssh' locally
                ShellCommand("chmod 0700 ~/.ssh"),
                CopyInto(location: "~/.ssh/\(keyName)", from: privateKeyLocation),
                CopyInto(location: "~/.ssh/\(keyName).pub", from: "\(privateKeyLocation).pub"),
                ShellCommand("chmod 0600 ~/.ssh/\(keyName)"),
                // CopyFrom(into: "swiftly-install.sh", from: URL(string: "https://swiftlang.github.io/swiftly/swiftly-install.sh")!),
                // ShellCommand("chmod 0755 swiftly-install.sh"),
                // released version (0.3.0) doesn't support Ubuntu 24.04 - that's pending in 0.4.0...
                // And 0.4.0 changes its installation process anyway...

                // Stop unattended upgrades during the updates
                ShellCommand("sudo systemctl stop unattended-upgrades.service"),

                // Apply all current upgrades available
                ShellCommand("sudo apt-get update -q", env: debUnattended),
                ShellCommand("sudo apt-get upgrade -y -qq", env: debUnattended),

                // latest upgrade looks like it _doesn't_ require a reboot to complete its work.
                //            ShellCommand("sudo reboot"),
                //            VerifyAccess(ignoreFailure: false,
                //                        retry: Backoff(maxRetries: 10, strategy: .fibonacci(maxDelay: .seconds(10)))),

                // "manual install" of Swift
                // from https://www.swift.org/install/linux/tarball/ for Ubuntu 24.04
                ShellCommand("sudo apt-get install -y -qq binutils", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq git", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq gnupg2", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libcurl4-openssl-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libstdc++-13-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libc6-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libgcc-13-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libncurses-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libpython3-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libsqlite3-0", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libxml2-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libz3-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq zlib1g-dev", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq unzip", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq pkg-config", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq tzdata", env: debUnattended),
                ShellCommand("sudo apt-get install -y -qq libedit2", env: debUnattended),

                // restart the unattended upgrades
                ShellCommand("sudo systemctl start unattended-upgrades.service"),

                // yes, I know about Swiftly, but when I'm creating this it wasn't available
                // on swift.org and the released version wasn't yet supporting Ubuntu 24.04.

                ShellCommand(
                    "wget -nv  https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz"
                ),
                // ~17 seconds
                ShellCommand("tar xzf swift-6.0.3-RELEASE-ubuntu24.04.tar.gz"),
                // ~43 seconds
                ShellCommand("swift-6.0.3-RELEASE-ubuntu24.04/usr/bin/swift -version"),

                // reboot to full apply pending updates
                ShellCommand("sudo reboot"),
            ])
    }
}
