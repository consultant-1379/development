#!/usr/bin/env python3
import logging
import itertools
import json
import argparse
import operator
import http.client
from functools import reduce

logger = logging.getLogger("dep_delta")
logger.setLevel(logging.INFO)

GITHUB_URL = "raw.githubusercontent.com"
CONSUL_PATH = "/hashicorp/consul/"
PRE_070_FILENAME = "/Godeps/Godeps.json"
POST_070_FILENAME = "/vendor/vendor.json"

def get_deps_github ( release_tag ):
    conn = http.client.HTTPSConnection(GITHUB_URL)
    if release_tag < "v0.7.0":
        logger.info("GETting %s%s%s%s", GITHUB_URL, CONSUL_PATH, release_tag, PRE_070_FILENAME)
        conn.request("GET", CONSUL_PATH + release_tag + PRE_070_FILENAME)
    else:
        logger.info("GETting %s%s%s%s", GITHUB_URL, CONSUL_PATH, release_tag, POST_070_FILENAME)
        conn.request("GET", CONSUL_PATH + release_tag + POST_070_FILENAME)
    with conn.getresponse() as rsp:
        if rsp.status < 300:
            logger.info("Received %d %s", rsp.status, rsp.reason)
            return str(rsp.read(), encoding='utf-8')
        else:
            logger.error("Response %d %s reading from GitHub", rsp.status, rsp.reason)

def process_json ( deps_json, release_tag ):
    return(
        process_pre070_json(deps_json) if release_tag < "v0.7.0"
        else process_post070_json(deps_json)
    )

def process_post070_json ( vendor_json ):
    pkg_list = map(lambda pkg: pkg["path"], vendor_json["package"])
    return pkg_list

def process_pre070_json ( godeps_json ):
    pkg_list = map(lambda pkg: pkg["ImportPath"], godeps_json["Deps"])
    pkg_list = reduce(operator.add, map(lambda pkg: pkg.split("/external/"), pkg_list), [])
    return pkg_list

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Detects delta of dependencies between releases of Consul"
    )
    parser.add_argument(
        'releaseA', metavar='RELEASE_A',
        type=str, nargs=1,
        help='The first release tag, dependencies in this release but not in the second one shall be reported')
    parser.add_argument(
        'releaseB', metavar='RELEASE_B',
        type=str, nargs=1,
        help='The second release tag, dependencies not in this release but in the first one shall be reported')

    args = parser.parse_args()

    try:
        setA = set(process_json(json.loads(get_deps_github(args.releaseA[0])), args.releaseA[0]))
        setB = set(process_json(json.loads(get_deps_github(args.releaseB[0])), args.releaseB[0]))
        diff = setA - setB
    except IOError as e:
        logger.error("I/O error accessing file: %s", e)
        exit(1)
    except KeyError as e:
        logger.error("Missing element in JSON content: %s", e)
        exit(2)
    except TypeError as e:
        logger.error("Problem with JSON content: %s", e)
        exit(3)

    print(diff or '{}')
    exit(0)
