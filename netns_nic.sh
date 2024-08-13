#!/bin/bash

# Check the number of parameters
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <interface_name> <namespace_name> [remove]"
    exit 1
fi

# Get parameters
INTERFACE=$1
NAMESPACE=$2
REMOVE=${3:-}

# Function to move interface to namespace
move_to_namespace() {
    # Check if the interface exists
    if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
        echo "Error: Interface $INTERFACE does not exist."
        exit 1
    fi

    # Check if the namespace exists
    if ! ip netns list | grep -w "$NAMESPACE" > /dev/null 2>&1; then
        # Create the namespace
        sudo ip netns add "$NAMESPACE"
    fi

    # Get the current configuration of the interface
    IP_ADDR=$(ip addr show "$INTERFACE" | grep 'inet ' | awk '{print $2}')
    GATEWAY=$(ip route | grep default | grep "$INTERFACE" | awk '{print $3}')

    # Check if the IP address was successfully obtained
    if [ -z "$IP_ADDR" ]; then
        echo "Error: Failed to get IP address of $INTERFACE."
        exit 1
    fi

    # Display the obtained configuration
    echo "Interface: $INTERFACE"
    echo "Namespace: $NAMESPACE"
    echo "IP Address: $IP_ADDR"
    echo "Gateway: $GATEWAY"

    # Move the interface to the specified namespace
    sudo ip link set "$INTERFACE" netns "$NAMESPACE"

    # Configure the interface in the new namespace
    sudo ip netns exec "$NAMESPACE" ip addr add "$IP_ADDR" dev "$INTERFACE"
    sudo ip netns exec "$NAMESPACE" ip link set "$INTERFACE" up
    sudo ip netns exec "$NAMESPACE" ip link set lo up

    sudo ip netns exec "$NAMESPACE" ip route add default dev "$INTERFACE"

    echo "Interface $INTERFACE has been moved to namespace $NAMESPACE and configured with IP $IP_ADDR."

    # Configure DNS in the new namespace
    NETNS_DIR="/etc/netns/${NAMESPACE}"
    if [ ! -d "${NETNS_DIR}" ]; then
        # Create /etc/netns directory
        sudo mkdir -p "${NETNS_DIR}"
        echo "Directory ${NETNS_DIR} created"
    else
        echo "Directory ${NETNS_DIR} already exists"
    fi

    # Configure resolv.conf file
    echo "nameserver 223.5.5.5" | sudo tee "${NETNS_DIR}/resolv.conf"
    echo "Configured DNS server for ${NAMESPACE} to 223.5.5.5"

    # Verify configuration
    echo "Verifying DNS configuration:"
    sudo ip netns exec "$NAMESPACE" cat /etc/resolv.conf

    # Attempt to ping a domain name within the namespace
    echo "Attempting to ping baidu.com within ${NAMESPACE}:"
    sudo ip netns exec "$NAMESPACE" ping -c 4 baidu.com

    # Enter the namespace
    echo ""
    echo "===================================="
    echo "Entering namespace $NAMESPACE"
    echo "===================================="
    sudo ip netns exec "$NAMESPACE" bash
}

# Function to move interface back to default namespace
move_to_default_namespace() {
    # Check if the interface exists in the namespace
    if ! sudo ip netns exec "$NAMESPACE" ip link show "$INTERFACE" > /dev/null 2>&1; then
        echo "Error: Interface $INTERFACE does not exist in namespace $NAMESPACE."
        exit 1
    fi

    # Record the interface configuration in the namespace
    IP_ADDR=$(sudo ip netns exec "$NAMESPACE" ip addr show "$INTERFACE" | grep 'inet ' | awk '{print $2}')
    GATEWAY=$(sudo ip netns exec "$NAMESPACE" ip route | grep default | awk '{print $3}')

    # Check if the IP address was successfully obtained
    if [ -z "$IP_ADDR" ]; then
        echo "Error: Failed to get IP address of $INTERFACE in namespace $NAMESPACE."
        exit 1
    fi

    # Display the obtained configuration
    echo "Interface: $INTERFACE"
    echo "Namespace: $NAMESPACE"
    echo "IP Address: $IP_ADDR"
    echo "Gateway: $GATEWAY"

    # Move the interface back to the default namespace
    sudo ip netns exec "$NAMESPACE" ip link set "$INTERFACE" netns 1

    # Reconfigure the interface in the default namespace
    sudo ip addr add "$IP_ADDR" dev "$INTERFACE"
    sudo ip link set "$INTERFACE" up

    echo "Interface $INTERFACE has been moved back to the default namespace and configured with IP $IP_ADDR."
}

# Main logic
if [ "$REMOVE" == "remove" ]; then
    move_to_default_namespace
else
    move_to_namespace
fi

# Inform the user how to run commands in the new namespace
if [ "$REMOVE" != "remove" ]; then
    echo "To run a command in the $NAMESPACE namespace, use:"
    echo "  sudo ip netns exec $NAMESPACE <command>"
fi
