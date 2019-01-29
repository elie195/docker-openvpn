# OpenVPN for Docker

[![Build Status](https://travis-ci.org/elie195/docker-openvpn.svg)](https://travis-ci.org/elie195/docker-openvpn)
[![Docker Stars](https://img.shields.io/docker/stars/elie195/openvpn.svg)](https://hub.docker.com/r/elie195/openvpn/)
[![Docker Pulls](https://img.shields.io/docker/pulls/elie195/openvpn.svg)](https://hub.docker.com/r/elie195/openvpn/)
[![ImageLayers](https://images.microbadger.com/badges/image/elie195/openvpn.svg)](https://microbadger.com/#/images/elie195/openvpn)

*Forked from [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn) in order to add support for Duo MFA*

OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

Extensively tested on [Digital Ocean $5/mo node](http://bit.ly/1C7cKr3) and has
a corresponding [Digital Ocean Community Tutorial](http://bit.ly/1AGUZkq).


## Quick Start (with Duo MFA support)

* Ensure you have an application of type "OpenVPN" created in your Duo Admin panel. If not, create a new application and note the **IKEY**, **SKEY**, and **HOST** values

* Pick a name for the `$OVPN_DATA` data volume container, it will be created automatically.

        OVPN_DATA="ovpn-data"

* Initialize the `$OVPN_DATA` container that will hold the configuration files and certificates

        docker run --name $OVPN_DATA -v /etc/openvpn -v /opt/duo busybox

* Grab the latest Duo OpenVPN plugin code and compile it

        docker run --volumes-from $OVPN_DATA --rm elie195/openvpn:build makeduo

* Generate configuration files and certificates (enter **IKEY**, **SKEY**, and **HOST** values when prompted). For the second step, pick a secure password for the OpenVPN Certificate Authority (CA). You can accept the default Common Name (CN) when prompted.

        docker run --volumes-from $OVPN_DATA --rm -it elie195/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM -3
        docker run --volumes-from $OVPN_DATA --rm -it elie195/openvpn ovpn_initpki

* Start OpenVPN server process

        docker run --volumes-from $OVPN_DATA -d -p 1194:1194/udp --cap-add=NET_ADMIN elie195/openvpn

* Generate a client certificate without a passphrase - **IMPORTANT**: Make sure to pick a username that exists in your Duo environment

        docker run --volumes-from $OVPN_DATA --rm -it elie195/openvpn easyrsa build-client-full CLIENTNAME nopass

* Retrieve the client configuration with embedded certificates

        docker run --volumes-from $OVPN_DATA --rm elie195/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

* Load the .ovpn file into your OpenVPN client of choice. **For push 2FA Duo prompts, set the password to "push" (no quotes)**

## Debugging Tips

* Custom setting for reneg-sec (default setting is '0', but it might not work with some clients)

        docker run --volumes-from $OVPN_DATA -e RENEG=36000 --rm -it elie195/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM -3

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

        docker run --volumes-from $OVPN_DATA -p 1194:1194/udp --privileged -e DEBUG=1 elie195/openvpn

* Test using a client that has openvpn installed correctly 

        $ openvpn --config CLIENTNAME.ovpn

* Run through a barrage of debugging checks on the client if things don't just work

        $ ping 8.8.8.8    # checks connectivity without touching name resolution
        $ dig google.com  # won't use the search directives in resolv.conf
        $ nslookup google.com # will use search


## Tested On

* Docker hosts:
  * server a [Digital Ocean](https://www.digitalocean.com/?refcode=d19f7fe88c94) Droplet with 512 MB RAM running Ubuntu 14.04
* Clients
  * iPhone OpenVPN Connect 1.0.7 (build 199, iOS 64-bit)
  * macOS Sierra with Tunnelblick 3.4beta26 (build 3828) using openvpn-2.3.4
     * A non-zero "reneg-sec" setting was required to get it to work. See "Custom setting for reneg-sec" in the Debugging Tips section above


## Having permissions issues with Selinux enabled?

See [this](docs/selinux.md)
