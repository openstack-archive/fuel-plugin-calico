#!/usr/bin/env python
# Copyright 2015 Metaswitch Networks

import yaml
from pluginutils import get_config_file_for_node_type

def main():
    config_file = get_config_file_for_node_type()

    with open(config_file, "r") as f:
        config = yaml.safe_load(f)

    # The route reflector should only peer with compute nodes.
    peer_ips = [node["internal_address"] for node in config["nodes"] 
                if node["role"] == "compute"]

    return peer_ips

if __name__ == "__main__":
    peer_ips = main()
    if peer_ips:
        print " ".join(peer_ips)

