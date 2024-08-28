#!/usr/bin/env python

import sys
import yaml
try:
    input_str = sys.stdin.read()
    yaml_data = yaml.safe_load(input_str)
    print yaml.dump(yaml_data, default_flow_style=False)
except ValueError,e:
    print "Couldn't decode \n %s \n Error : %s"%(input_str, str(e))
