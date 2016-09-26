#!/bin/bash
set -e

set -x
[ -n "${DEBUG+x}" ] && set -x

OVPN_DATA=basic-data-otp
CLIENT=travis-client
#Change once merged
IMG=elie195/openvpn
OTP_USER=otp
#Duo testing config
IKEY=testIKEY
SKEY=testSKEY
HOST=testHOST
CLIENT_DIR="$(readlink -f "$(dirname "$BASH_SOURCE")/../../client")"

# Function to fail
abort() { cat <<< "$@" 1>&2; exit 1; }

ip addr ls
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
# Configure server with Duo two factor authentication
docker run -e "IKEY=$IKEY" -e "SKEY=$SKEY" -e "HOST=$HOST" -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_genconfig -u udp://$SERV_IP -3

# nopass is insecure
docker run -v $OVPN_DATA:/etc/openvpn --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

docker run -v $OVPN_DATA:/etc/openvpn --rm -it $IMG easyrsa build-client-full $CLIENT nopass

# Override the auth-user-pass directive to use a credentials file
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_getclient $CLIENT | tee $CLIENT_DIR/config.ovpn

#Check that config was properly generated
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG grep -q "duo_openvpn.so"

#Check that client config was properly generated
grep -q reneg-sec $CLIENT_DIR/config.ovpn

#
# Fire up the server
#
sudo iptables -N DOCKER || echo 'Firewall already configured'
sudo iptables -I FORWARD -j DOCKER || echo 'Forward already configured'
# run in shell bg to get logs
docker run --name "ovpn-test" -v $OVPN_DATA:/etc/openvpn --rm -p 1194:1194/udp --privileged $IMG &

#for i in $(seq 10); do
#    SERV_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}')
#    test -n "$SERV_IP" && break
#done
#sed -ie s:SERV_IP:$SERV_IP:g $CLIENT_DIR/config.ovpn

#
# Fire up a client in a container since openvpn is disallowed by Travis-CI, don't NAT
# the host as it confuses itself:
# "Incoming packet rejected from [AF_INET]172.17.42.1:1194[2], expected peer address: [AF_INET]10.240.118.86:1194"
#
#docker run --rm --net=host --privileged --volume $CLIENT_DIR:/client $IMG /client/wait-for-connect.sh

#
# Client either connected or timed out, kill server
#
kill %1

#
# Celebrate
#
cat <<EOF
 ___________
< it worked >
 -----------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\\
                ||----w |
                ||     ||
EOF
