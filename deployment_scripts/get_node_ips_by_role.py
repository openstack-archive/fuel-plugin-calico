#!/usr/bin/env python
# Copyright 2015 Metaswitch Networks

import argparse
import yaml

from pluginutils import NODES_CONFIG


def main(node_roles):
    with open(NODES_CONFIG, "r") as f:
        config = yaml.safe_load(f)

    node_ips = [node["internal_address"] for node in config["nodes"] 
                if node["role"] in node_roles]

    return node_ips


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("node_role", choices=["compute", "controller"])
    args = parser.parse_args()

    args.node_role = [args.node_role]
    if args.node_role == ["controller"]:
        args.node_role.append("primary-controller")

    node_ips = main(args.node_role)
    if node_ips:
        print " ".join(node_ips)

