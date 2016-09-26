#!/bin/bash
set -e

testAlias+=(
	[elie195/openvpn]='openvpn'
)

imageTests+=(
	[openvpn]='
		paranoid
        conf_options
        basic
        dual-proto
        otp
	duo
	'
)
