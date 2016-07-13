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
    print config["network_metadata"]["nodes"]
    for node in config["network_metadata"]["nodes"]:
        if config["network_metadata"]["nodes"][node]["fqdn"] == hostname:
            # Get the IP address that other OpenStack nodes can use to address
            # services on this node, rather than the node's public IP address.
            this_node_ip = config["network_metadata"]["nodes"][node]["network_roles"]["mgmt/vip"]
            break
    else:
        this_node_ip = None

    print this_node_ip

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print usage
        sys.exit(1)

    main(sys.argv[1])
