// generated with a local run of `ssh-keygen -t ed25519`

// ======= WARNING ======= WARNING ======= WARNING ======= WARNING ======= WARNING =======
// DO NOT re-use this key for any other purpose. It is in a public repository, it's not secure.
// ======= WARNING ======= WARNING ======= WARNING ======= WARNING ======= WARNING =======

// This key was set up specifically to work functional to integration style tests.
// CI defines a (configurable) docker-image running on OpenSSH Server on port 2222:
//
// services:
//      ssh-server:
//        image: lscr.io/linuxserver/openssh-server
//        # docs: https://hub.docker.com/r/linuxserver/openssh-server
//        ports:
//          - 2222:2222
//        env:
//          USER_NAME: fred
//          PUBLIC_KEY: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILKOAW7T4zC85n97IR/rxe+LDzyny2a8xa22htpNm+e+ heckj@Sparrow.local

struct TestKey {

    static let privateKey = """
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
        QyNTUxOQAAACCyjgFu0+MwvOZ/eyEf68Xviw88p8tmvMWttobaTZvnvgAAAJj4Ho6T+B6O
        kwAAAAtzc2gtZWQyNTUxOQAAACCyjgFu0+MwvOZ/eyEf68Xviw88p8tmvMWttobaTZvnvg
        AAAEBbbEy3hth2iYi1dMllzcQ3jXT5HNnDhCPgqVVC9Hfkj7KOAW7T4zC85n97IR/rxe+L
        Dzyny2a8xa22htpNm+e+AAAAE2hlY2tqQFNwYXJyb3cubG9jYWwBAg==
        -----END OPENSSH PRIVATE KEY-----
        """

    static let publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILKOAW7T4zC85n97IR/rxe+LDzyny2a8xa22htpNm+e+ heckj@Sparrow.local"
}
