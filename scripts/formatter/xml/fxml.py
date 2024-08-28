#!/usr/bin/env python

import sys
import xml.dom.minidom
try:
    input_str=sys.stdin.read()
    print xml.dom.minidom.parseString(input_str).toprettyxml(indent="    ")
except ValueError,e:
    print "Couldn't decode \n %s \n Error : %s"%(input_str, str(e))
