#!/bin/bash
# Copyright 2015-2016 Metaswitch Networks

exec >> /tmp/calico_route_reflector.log 2>&1

set -x

echo "================ `date` ================"
echo "Hi, I'm a route_reflector node!"

# Calculate IP addresses of route reflector peers.
this_node_address=$(python get_node_ip.py `hostname`)
controller_node_addresses=$(python get_controller_ips.py)
route_reflector_peers=("${controller_node_addresses[@]/$this_node_address}")

# Use /etc/hosts to get IP addresses of all other Fuel nodes.
client_peers=`awk 'NF==3 {print $1;}' /etc/hosts | sort | uniq`

# Remove the controller IPs from that set.
for controller_ip in $controller_node_addresses; do
  client_peers=${client_peers/$controller_ip}
done

# Generate basic config for a BIRD BGP route reflector.
cat > /etc/bird/bird.conf <<EOF
# Configure logging
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
log stderr all;
#log "tmp" all;

# Override router ID
router id $this_node_address;


filter import_kernel {
if ( net != 0.0.0.0/0 ) then {
   accept;
   }
reject;
}

# Turn on global debugging of all protocols
debug protocols all;

# This pseudo-protocol watches all interface up/down events.
protocol device {
  scan time 2;    # Scan interfaces every 10 seconds
}
EOF

# Add a BGP protocol stanza for all peers.
for node in ${client_peers[@]} ${route_reflector_peers[@]}; do
  cat >> /etc/bird/bird.conf <<EOF
protocol bgp {
  local as 64511;
  neighbor $node as 64511;
  multihop;
EOF

  if [[ "${client_peers[@]}" =~ "${node}" ]]; then
    cat >> /etc/bird/bird.conf <<EOF
  description "Client $node";
  rr client;
EOF
  else
    cat >> /etc/bird/bird.conf <<EOF
  description "Route Reflector $node";
EOF
  fi

  cat >> /etc/bird/bird.conf <<EOF
  rr cluster id 1.2.3.4;
  import all;
  export all;
  source address ${this_node_address};
}
EOF
done

# Restart BIRD with the new config.
service bird restart

exit 0
