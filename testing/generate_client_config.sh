#!/bin/bash
source versions.sh

for CLIENT_NAME in "${CLIENT_IMAGE_VERSIONS[@]}"; do
    CLIENT_CONF="/home/openvpn/config/client-${CLIENT_NAME}.conf"
    
    echo "Generating client configuration file: $CLIENT_CONF"
    
    > "$CLIENT_CONF"
    
    cat >> "$CLIENT_CONF" << 'EOF'
client
dev tun
EOF
if [[ "${CLIENT_NAME}" == "bookworm" && "${OPENVPN_VERSION}" == v2.7* ]]; then
    echo "remote 192.168.200.100 443 tcp" >> "$CLIENT_CONF"
else
    echo "remote 192.168.200.100 443 tcp" >> "$CLIENT_CONF"
fi
cat >> "$CLIENT_CONF" << 'EOF'
resolv-retry infinite
nobind
persist-tun
auth-nocache
EOF
    
    echo "<cert>" >> "$CLIENT_CONF"
    cat "/home/openvpn/config/${CLIENT_NAME}.crt" >> "$CLIENT_CONF"
    echo "</cert>" >> "$CLIENT_CONF"
    
    echo "<key>" >> "$CLIENT_CONF"
    cat "/home/openvpn/config/${CLIENT_NAME}.key" >> "$CLIENT_CONF"
    echo "</key>" >> "$CLIENT_CONF"
    
    echo "<ca>" >> "$CLIENT_CONF"
    cat /home/openvpn/config/ca/ca.crt >> "$CLIENT_CONF"
    echo "</ca>" >> "$CLIENT_CONF"
    
    if [[ "${OPENVPN_VERSION}" == v2.7* ]]; then
        echo "<tls-crypt>" >> "$CLIENT_CONF"
        cat /home/openvpn/config/ta_crypt.key >> "$CLIENT_CONF"
        echo "</tls-crypt>" >> "$CLIENT_CONF"
        cat >> "$CLIENT_CONF" << 'EOF'
data-ciphers AES-256-GCM
verb 3
EOF
    elif [[ "${OPENVPN_VERSION}" == v2.6* ]]; then
        echo "<tls-crypt>" >> "$CLIENT_CONF"
        cat /home/openvpn/config/ta.key >> "$CLIENT_CONF"
        echo "</tls-crypt>" >> "$CLIENT_CONF"
        cat >> "$CLIENT_CONF" << 'EOF'
key-direction 1
cipher AES-256-GCM
data-ciphers AES-256-GCM
data-ciphers-fallback AES-256-CBC
verb 3
EOF
    else
        echo "WARNING: Unsupported OPENVPN_VERSION '${OPENVPN_VERSION}', skipping TLS config for ${CLIENT_NAME}"
    fi
    
    echo "### CLIENT CONFIG: $CLIENT_CONF ###"
    cat "$CLIENT_CONF"
    echo ""
done

echo "All client configurations generated successfully"
wait