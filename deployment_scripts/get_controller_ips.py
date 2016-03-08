#!/usr/bin/env python
# Copyright 2015-2016 Metaswitch Networks

import yaml

from pluginutils import ASTUTE_CONFIG


def main(node_roles):
    with open(ASTUTE_CONFIG, "r") as f:
        config = yaml.safe_load(f)

    node_ips = [node["internal_address"] for node in config["nodes"]
                if node["role"] in node_roles]

    return node_ips


if __name__ == "__main__":
    node_ips = main(["controller", "primary-controller"])
    if node_ips:
        print " ".join(node_ips)
