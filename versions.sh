#!/bin/bash
IMAGE_VERSION='v1.1.4'
OPENVPN_VERSION='v2.7.2' # For upgrade, please update also value in server/openvpn.dockerfile
CLIENT_IMAGE_VERSIONS=("bullseye" "bookworm" "jammy")