#!/usr/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

source /etc/functions.sh
clear
print_header "Network and storage defaults"
print_status "Detecting public IP, IPv6, distro, and storage paths"

# If the machine is behind a NAT, inside a VM, etc., it may not know
# its IP address on the public network / the Internet. Ask the Internet
# and possibly confirm with user.
if [ -z "${PUBLIC_IP:-}" ]; then
# Ask the Internet.
GUESSED_IP=$(get_publicip_from_web_service 4)

# On the first run, if we got an answer from the Internet then don't
# ask the user.
if [[ -z "${DEFAULT_PUBLIC_IP:-}" && ! -z "$GUESSED_IP" ]]; then
PUBLIC_IP=$GUESSED_IP

# On later runs, if the previous value matches the guessed value then
# don't ask the user either.
elif [ "${DEFAULT_PUBLIC_IP:-}" == "$GUESSED_IP" ]; then
PUBLIC_IP=$GUESSED_IP
fi

if [ -z "${PUBLIC_IP:-}" ]; then
input_box "Public IP Address" \
"Enter the public IP address of this machine, as given to you by your ISP.
\n\nPublic IP address:" \
"$DEFAULT_PUBLIC_IP" \
PUBLIC_IP

if [ -z "$PUBLIC_IP" ]; then
# user hit ESC/cancel
exit
fi
fi
fi

# Same for IPv6. But it's optional. Also, if it looks like the system
# doesn't have an IPv6, don't ask for one.
if [ -z "${PUBLIC_IPV6:-}" ]; then
	# Ask the Internet.
	GUESSED_IP=$(get_publicip_from_web_service 6)
	MATCHED=0
	if [[ -z "${DEFAULT_PUBLIC_IPV6:-}" && ! -z "$GUESSED_IP" ]]; then
		PUBLIC_IPV6=$GUESSED_IP
	elif [[ "${DEFAULT_PUBLIC_IPV6:-}" == "$GUESSED_IP" ]]; then
		# No IPv6 entered and machine seems to have none, or what
		# the user entered matches what the Internet tells us.
		PUBLIC_IPV6=$GUESSED_IP
		MATCHED=1
	elif [[ -z "${DEFAULT_PUBLIC_IPV6:-}" ]]; then
		DEFAULT_PUBLIC_IP=$(get_default_privateip 6)
	fi

	if [[ -z "${PUBLIC_IPV6:-}" && $MATCHED == 0 ]]; then
		input_box "IPv6 Address (Optional)" \
			"Enter the public IPv6 address of this machine, as given to you by your ISP.
			\n\nLeave blank if the machine does not have an IPv6 address.
			\n\nPublic IPv6 address:" \
			${DEFAULT_PUBLIC_IPV6:-} \
			PUBLIC_IPV6

		if [ ! $PUBLIC_IPV6_EXITCODE ]; then
			# user hit ESC/cancel
			exit
		fi
	fi
fi

# Get the IP addresses of the local network interface(s) that are connected
# to the Internet. We need these when we want to have services bind only to
# the public network interfaces (not loopback, not tunnel interfaces).
# if [ -z "$PRIVATE_IP" ]; then
# DEFAULT_PRIVATE_IP=$(get_default_privateip 4)
# input_box "Private IP Address (Optional)" \
# "Enter the private IP address of this machine, as given to you by your ISP.
# \n\nLeave as your public IP if the machine does not have a private IP address.
# \n\nPrivate IP address:" \
# $DEFAULT_PRIVATE_IP \
# PRIVATE_IP
#
#  if [ -z "$PRIVATE_IP" ]; then
# user hit ESC/cancel
# exit
#  fi
# fi

# Automatic configuration, e.g. as used in our Vagrant configuration.
if [ "$PUBLIC_IP" = "auto" ]; then
# Use a public API to get our public IP address, or fall back to local network configuration.
PUBLIC_IP=$(get_publicip_from_web_service 4 || get_default_privateip 4)
fi
if [ "$PUBLIC_IPV6" = "auto" ]; then
# Use a public API to get our public IPv6 address, or fall back to local network configuration.
PUBLIC_IPV6=$(get_publicip_from_web_service 6 || get_default_privateip 6)
fi

# Fallback: detect DISTRO if not already set by preflight.sh
if [ -z "${DISTRO:-}" ]; then
    if [ -f /etc/lsb-release ]; then
        _ver=$(lsb_release -rs)
        case "$_ver" in
            25.04) DISTRO=25 ;;
            24.04) DISTRO=24 ;;
            23.04) DISTRO=23 ;;
            22.04) DISTRO=22 ;;
            *)     DISTRO=22 ;;
        esac
    elif [ -f /etc/debian_version ]; then
        _ver=$(cut -d. -f1 /etc/debian_version)
        case "$_ver" in
            13) DISTRO=13 ;;
            12) DISTRO=12 ;;
            11) DISTRO=11 ;;
            *)  DISTRO=12 ;;
        esac
    fi
fi

# Fallback: set STORAGE_USER and STORAGE_ROOT if not already set by preflight.sh
if [ -z "${STORAGE_USER:-}" ]; then
    STORAGE_USER="crypto-data"
fi
if [ -z "${STORAGE_ROOT:-}" ]; then
    STORAGE_ROOT="/home/${STORAGE_USER}"
fi

# Set PRIVATE_IP from the default network interface
if [ -z "${PRIVATE_IP:-}" ]; then
    PRIVATE_IP=$(get_default_privateip 4)
fi