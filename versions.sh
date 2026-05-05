#!/bin/bash
IMAGE_VERSION='v1.1.6'
OPENVPN_VERSION='v2.7.4' # For upgrade, please update also value in server/openvpn.dockerfile
CLIENT_IMAGE_VERSIONS=("bullseye" "bookworm" "jammy")