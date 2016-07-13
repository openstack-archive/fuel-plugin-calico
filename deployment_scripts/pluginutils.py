#!/usr/bin/env python
# Copyright 2015 Metaswitch Networks

import os

# This config file is updated with the latest node details as the deployment
# evolves. It only contains node details, not other config settings.
NODES_CONFIG = "/etc/hiera/astute.yaml"

# These config files contain details of the nodes at initial deployment, but
# they are not subsequently updated with node changes. However, they contain
# a greater range of information, including settings and network config. They
# are also created on the system earlier in the deployment process, so are
# good sources of initial node information during Calico setup.
PRIMARY_CONTROLLER_CFG = NODES_CONFIG
CONTROLLER_CFG = NODES_CONFIG
COMPUTE_CFG = NODES_CONFIG

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
