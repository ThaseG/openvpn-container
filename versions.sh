#!/bin/bash
IMAGE_VERSION='v1.1.2'
OPENVPN_VERSION='v2.7.1' # For upgrade, please update also value in server/openvpn.dockerfile
CLIENT_IMAGE_VERSIONS=("bullseye" "bookworm" "jammy")