#!/bin/bash

exec > /tmp/calico_route_reflector.log 2>&1

set -x

echo "Hi, I'm a route_reflector node!"

this_node_address=$(grep `hostname` /etc/hosts | awk '{print $1;}')

all_nodes=$(grep node- /etc/hosts | awk '{print $1;}')

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

# Add a BGP protocol stanza for each compute node.
for node in $all_nodes; do
    if [ $node != $this_node_address ]; then
        cat >> /etc/bird/bird.conf <<EOF

protocol bgp {
  description "$node";
  local as 64511;
  neighbor $node as 64511;
  multihop;
  rr client;
  import all;
  export all;
  source address ${this_node_address};
}

EOF
    fi
done

# Restart BIRD with the new config.
service bird restart

exit 0
