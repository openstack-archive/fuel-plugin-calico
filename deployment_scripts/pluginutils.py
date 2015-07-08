#!/usr/bin/env python
# Copyright 2015 Metaswitch Networks

import os

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
