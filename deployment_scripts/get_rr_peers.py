#!/usr/bin/env python
# Copyright 2015 Metaswitch Networks

import yaml

from pluginutils import NODES_CONFIG

def main():
    with open(NODES_CONFIG, "r") as f:
        config = yaml.safe_load(f)

    # The route reflector should only peer with compute nodes.
    peer_ips = [node["internal_address"] for node in config["nodes"] 
                if node["role"] == "compute"]

    return peer_ips

if __name__ == "__main__":
    peer_ips = main()
    if peer_ips:
        print " ".join(peer_ips)

