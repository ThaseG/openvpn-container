#!/bin/bash
# Container image version
IMAGE_VERSION='v1.1.10'

# Component versions. The ENV defaults in server/openvpn.dockerfile must be
# kept in sync; scripts/check-updates.sh updates both.
OPENVPN_VERSION='v2.7.9'
OPENVPN_EXPORTER_VERSION='v1.1.2'
GO_VERSION='1.27.4'

CLIENT_IMAGE_VERSIONS=("bookworm" "jammy")
