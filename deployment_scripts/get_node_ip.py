#!/usr/bin/env python

import os
import sys
import yaml

usage = "./get_node_ip.py <hostname>"

PRIMARY_CONTROLLER_CFG = "/etc/primary-controller.yaml"
CONTROLLER_CFG = "/etc/controller.yaml"
COMPUTE_CFG = "/etc/compute.yaml"

def get_config_file_for_node_type():
    if os.path.isfile(PRIMARY_CONTROLLER_CFG):
        config_file = PRIMARY_CONTROLLER_CFG

    elif os.path.isfile(CONTROLLER_CFG):
        config_file = CONTROLLER_CFG

    elif os.path.isfile(COMPUTE_CFG):
        config_file = COMPUTE_CFG

    else:
        raise Exception("Unrecognised node type - can't obtain config")

    return config_file

def main(hostname):
    config_file = get_config_file_for_node_type()

    with open(config_file, "r") as f:
        config = yaml.safe_load(f)

    for node in config["nodes"]:
        if node["fqdn"] == hostname:
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
