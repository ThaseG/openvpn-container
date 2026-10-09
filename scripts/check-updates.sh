#!/bin/bash
# check-updates.sh - check upstream for new OpenVPN, openvpn-exporter and Go
# releases and update the repository in place.
#
# When something newer is found it updates versions.sh, the ENV defaults in
# server/openvpn.dockerfile and CHANGELOG.md, and bumps IMAGE_VERSION (minor
# for a new OpenVPN minor release, see CONTRIBUTING.md; patch otherwise).
# Review the result with `git diff`.
#
# Output:
#   stdout          Markdown summary (used as the pull request body)
#   stderr          progress log
#   GITHUB_OUTPUT   changed=true|false, title=<PR/commit title>,
#                   image_version=<new IMAGE_VERSION> (when run in Actions)
#
# Requirements: bash 4+, curl, git, perl, python3

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source ./versions.sh

DOCKERFILE="server/openvpn.dockerfile"
CHANGELOG="CHANGELOG.md"
OPENVPN_REPO="https://github.com/OpenVPN/openvpn"
EXPORTER_REPO="https://github.com/ThaseG/openvpn-exporter"

log() { echo "$*" >&2; }

# newer <candidate> <current> - true if candidate sorts after current
newer() {
    [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

# minor <version> - major.minor, ignoring a "v" prefix
minor() { local v="${1#v}"; echo "${v%.*}"; }

# major <version> - leading number, ignoring a "v" prefix
major() { local v="${1#v}"; echo "${v%%.*}"; }

# latest_tag <repo> - newest vX.Y.Z tag (release candidates and betas excluded)
latest_tag() {
    git ls-remote --tags --refs "$1" |
        sed 's#.*refs/tags/##' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1
}

# set_shell_var <NAME> <value> - NAME='value' in versions.sh
set_shell_var() {
    NAME="$1" VALUE="$2" perl -pi -e \
        's/^\Q$ENV{NAME}\E=.*$/$ENV{NAME}=\x27$ENV{VALUE}\x27/' versions.sh
    grep -qx "$1='$2'" versions.sh || { log "ERROR: could not update $1 in versions.sh"; exit 1; }
}

# set_docker_env <NAME> <value> - ENV NAME=value in the Dockerfile
set_docker_env() {
    NAME="$1" VALUE="$2" perl -pi -e \
        's/^ENV \Q$ENV{NAME}\E=.*$/ENV $ENV{NAME}=$ENV{VALUE}/' "$DOCKERFILE"
    grep -qx "ENV $1=$2" "$DOCKERFILE" || { log "ERROR: could not update ENV $1 in $DOCKERFILE"; exit 1; }
}

changes=()       # human-readable lines for the changelog / PR body
title_parts=()   # short fragments for the PR title
warnings=()
rows=()          # summary table rows
openvpn_minor_bump=false

# --- OpenVPN ------------------------------------------------------------------
log "Checking OpenVPN (current ${OPENVPN_VERSION})..."
latest_ovpn=$(latest_tag "$OPENVPN_REPO")
[ -n "$latest_ovpn" ] || { log "ERROR: could not determine latest OpenVPN release"; exit 1; }

if newer "$latest_ovpn" "$OPENVPN_VERSION"; then
    log "  new release ${latest_ovpn}"
    set_shell_var OPENVPN_VERSION "$latest_ovpn"
    set_docker_env OPENVPN_VERSION "$latest_ovpn"
    changes+=("OpenVPN ${OPENVPN_VERSION} → ${latest_ovpn} ([release notes](${OPENVPN_REPO}/releases/tag/${latest_ovpn}))")
    title_parts+=("OpenVPN ${latest_ovpn}")
    rows+=("| OpenVPN | ${OPENVPN_VERSION} | ${latest_ovpn} | updated |")
    if [ "$(minor "$latest_ovpn")" != "$(minor "$OPENVPN_VERSION")" ]; then
        openvpn_minor_bump=true
        warnings+=("OpenVPN feature release (${OPENVPN_VERSION} → ${latest_ovpn}): testing/generate_*_config.sh select TLS/cipher options by version prefix (v2.6*/v2.7*) and may need a new branch.")
    fi
else
    rows+=("| OpenVPN | ${OPENVPN_VERSION} | ${latest_ovpn} | up to date |")
fi

# --- openvpn-exporter -----------------------------------------------------------
log "Checking openvpn-exporter (current ${OPENVPN_EXPORTER_VERSION})..."
latest_exp=$(latest_tag "$EXPORTER_REPO")
[ -n "$latest_exp" ] || { log "ERROR: could not determine latest exporter tag"; exit 1; }

if newer "$latest_exp" "$OPENVPN_EXPORTER_VERSION"; then
    log "  new release ${latest_exp}"
    set_shell_var OPENVPN_EXPORTER_VERSION "$latest_exp"
    set_docker_env OPENVPN_EXPORTER_VERSION "$latest_exp"
    changes+=("openvpn-exporter ${OPENVPN_EXPORTER_VERSION} → ${latest_exp} ([changes](${EXPORTER_REPO}/compare/${OPENVPN_EXPORTER_VERSION}...${latest_exp}))")
    title_parts+=("openvpn-exporter ${latest_exp}")
    rows+=("| openvpn-exporter | ${OPENVPN_EXPORTER_VERSION} | ${latest_exp} | updated |")
    [ "$(major "$latest_exp")" != "$(major "$OPENVPN_EXPORTER_VERSION")" ] &&
        warnings+=("openvpn-exporter major version change (${OPENVPN_EXPORTER_VERSION} → ${latest_exp}): check for metric or config changes.")
else
    rows+=("| openvpn-exporter | ${OPENVPN_EXPORTER_VERSION} | ${latest_exp} | up to date |")
fi

# --- Go -------------------------------------------------------------------------
# Tracked as a full version: the Dockerfile downloads go<version>.linux-amd64.tar.gz.
log "Checking Go (current ${GO_VERSION})..."
latest_go=$(curl -fsSL 'https://go.dev/dl/?mode=json' | python3 -c '
import json, sys
versions = [r["version"][2:] for r in json.load(sys.stdin) if r.get("stable")]
print(sorted(versions, key=lambda v: tuple(map(int, v.split("."))))[-1])
')
[ -n "$latest_go" ] || { log "ERROR: could not determine latest Go release"; exit 1; }

if newer "$latest_go" "$GO_VERSION"; then
    log "  new release ${latest_go}"
    set_shell_var GO_VERSION "$latest_go"
    set_docker_env GO_VERSION "$latest_go"
    if [ "$(minor "$latest_go")" != "$(minor "$GO_VERSION")" ]; then
        notes="https://go.dev/doc/go$(minor "$latest_go")"
    else
        notes="https://go.dev/doc/devel/release#go${latest_go}"
    fi
    changes+=("Go ${GO_VERSION} → ${latest_go} ([release notes](${notes}))")
    title_parts+=("Go ${latest_go}")
    rows+=("| Go | ${GO_VERSION} | ${latest_go} | updated |")
else
    rows+=("| Go | ${GO_VERSION} | ${latest_go} | up to date |")
fi

# --- Results --------------------------------------------------------------------
gh_output() { [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1" >> "$GITHUB_OUTPUT" || true; }

summary_table() {
    echo "| Component | Current | Latest | Status |"
    echo "| --------- | ------- | ------ | ------ |"
    printf '%s\n' "${rows[@]}"
}

if [ "${#changes[@]}" -eq 0 ]; then
    log "Everything is up to date."
    gh_output "changed=false"
    echo "## Weekly version check"
    echo
    echo "Everything is up to date."
    echo
    summary_table
    exit 0
fi

# Bump IMAGE_VERSION: a new OpenVPN minor release bumps MINOR, anything else PATCH
if [[ ! "$IMAGE_VERSION" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    log "ERROR: IMAGE_VERSION '${IMAGE_VERSION}' is not vX.Y.Z"
    exit 1
fi
old_image="$IMAGE_VERSION"
if [ "$openvpn_minor_bump" = true ]; then
    new_image="v${BASH_REMATCH[1]}.$((BASH_REMATCH[2] + 1)).0"
else
    new_image="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.$((BASH_REMATCH[3] + 1))"
fi
set_shell_var IMAGE_VERSION "$new_image"

# Changelog row (newest first, right below the table header)
source ./versions.sh
ubuntu_version=$(sed -n 's/^FROM ubuntu:\([^ ]*\).*/\1/p' "$DOCKERFILE" | tail -1)
change_text=$(printf '%s <BR> - ' "${changes[@]}")
row="| ${new_image}  | $(date -u +%F)   | **OpenVPN Version**: \`${OPENVPN_VERSION#v}\` </br> **OpenVPN Exporter Version**: \`${OPENVPN_EXPORTER_VERSION#v}\` </br> **golang Version**: \`${GO_VERSION}\` </br> **Ubuntu Version**: \`${ubuntu_version}\` | Automated dependency update: <BR> - ${change_text%' <BR> - '} | No |"
ROW="$row" perl -0pi -e 's/^(\| -------.*\n)/$1$ENV{ROW}\n/m' "$CHANGELOG"
grep -qF "| ${new_image}  |" "$CHANGELOG" || { log "ERROR: could not add changelog row"; exit 1; }

title="Update $(IFS=,; echo "${title_parts[*]}" | sed 's/,/, /g') (${new_image})"
log "$title"
gh_output "changed=true"
gh_output "image_version=${new_image}"
gh_output "title=${title}"

echo "## ${title}"
echo
echo "Automated weekly version check found new upstream releases."
echo
summary_table
echo
echo "### Changes"
printf -- '- %s\n' "${changes[@]}"
if [ "${#warnings[@]}" -gt 0 ]; then
    echo
    echo "### ⚠️ Needs attention"
    printf -- '- %s\n' "${warnings[@]}"
fi
echo
echo "Files updated: \`versions.sh\`, \`${DOCKERFILE}\`, \`${CHANGELOG}\` (IMAGE_VERSION ${old_image} → ${new_image})."
echo
echo "Merge only after the Validation Workflow (build, Trivy, e2e) passes on this pull request."
