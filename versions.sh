#!/bin/bash
# Container image version
IMAGE_VERSION='v1.1.8'

# Component versions. The ENV defaults in server/openvpn.dockerfile must be
# kept in sync; scripts/check-updates.sh updates both.
OPENVPN_VERSION='v2.7.8'
OPENVPN_EXPORTER_VERSION='v1.1.1'
GO_VERSION='1.27.2'

CLIENT_IMAGE_VERSIONS=("bookworm" "jammy")
