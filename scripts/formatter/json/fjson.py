#!/usr/bin/env python

import json
import sys
try:
    input_str = sys.stdin.read()
    json_data = json.loads(input_str)
    print json.dumps(json_data, sort_keys=True, indent=2)
except ValueError,e:
    print "Couldn't decode \n %s \n Error : %s"%(input_str, str(e))