#!/usr/bin/env python
# Copyright 2015 Metaswitch Networks

import sys
import yaml
from pluginutils import get_config_file_for_node_type

usage = "./get_node_ip.py <hostname>"

def main(hostname):
    config_file = get_config_file_for_node_type()

    with open(config_file, "r") as f:
        config = yaml.safe_load(f)

    for node in config["nodes"]:
        if node["fqdn"] == hostname:
            # Get the IP address that other OpenStack nodes can use to address
            # services on this node, rather than the node's public IP address.
            this_node_ip = node["internal_address"]
            break
    else:
        this_node_ip = None

    print this_node_ip

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print usage
        sys.exit(1)

    main(sys.argv[1])
