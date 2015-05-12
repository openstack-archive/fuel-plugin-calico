#!/usr/bin/env python

import yaml

with open("/etc/compute.yaml", "r") as f:
    config = yaml.safe_load(f)

for node in config["nodes"]:
    if node["role"] == "primary-controller":
        controller_ip = node["internal_address"]
        break
else:
    controller_ip = None

print controller_ip
