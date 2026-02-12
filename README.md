# OpenVPN Server

A production-ready OpenVPN server running in Docker with built-in monitoring and metrics export capabilities. Tests in pipelines are testing the versions of OpenVPN, exporter, and IPtables rules.

## Used Exporter

Exporter used in this project is from a dedicated [repository here.](https://github.com/ThaseG/openvpn-exporter)

## Features

- 🔒 OpenVPN 2.6.19 - Built from source for latest security features
- 🐳 Docker-based - Easy deployment and management
- 📊 Prometheus Metrics - Built-in OpenVPN exporter for monitoring
- 🔄 Dual Protocol Support - Run TCP and UDP instances simultaneously
- 🛡️ Security First - Runs as non-root user with minimal privileges
- 📝 Flexible Configuration - Easy to customize via mounted configs
- 🔧 iptables Support - Custom firewall rules support

Note: 🔒 OpenVPN 2.7.0 - comming soon

## Configuration
### Required Files

Mount these files to /home/openvpn/config/:

- `server-common.conf` - Common OpenVPN settings (required)
- `server-tcp.conf` - TCP-specific configuration (optional)
- `server-udp.conf` - UDP-specific configuration (optional)
- `iptables.sh` - Custom firewall rules (optional)

### Configuration Structure

```
/home/openvpn/config/
├── server-common.conf    # Shared settings
├── server-tcp.conf       # TCP instance config
├── server-udp.conf       # UDP instance config
├── iptables.sh           # Firewall rules (optional)
├── ca.crt                # Certificate Authority
├── server.crt            # Server certificate
├── server.key            # Server private key
├── dh.pem                # Diffie-Hellman parameters
└── ta.key                # TLS auth key (optional)
```

## License
MIT License - feel free to use and modify as needed.

## For more information:

 - the [CONTRIBUTING](./CONTRIBUTING.md) document describes how to contribute to the repository
 - in case of need, please contact owner group : [ThaseG](mailto:andrej@hyben.net)
 - see [Changelog](./CHANGELOG.md) for release information.
 - check [Upgrade procedure](./UPGRADE.md) to see how to create new openvpn container image.
 - check [Tests](./Tests.md) to see how automated tests works within this repository to verify version.
