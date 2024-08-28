#!/usr/bin/env python

import os
import yaml
import argparse

import subprocess

def parse_arguments():
    """ Parse arguments from main method """
    git_root = subprocess.Popen("git rev-parse --show-toplevel 2> /dev/null",
        stdout=subprocess.PIPE, shell=True).stdout.read().strip()
    parser = argparse.ArgumentParser()
    parser.add_argument("yaml_key",
                        help="Yaml Key into package.yaml")
    parser.add_argument("installation_mode",
                        help="The installation mode. "
                             "Available options are: development/production")
    parser.add_argument("project_path", default=git_root, nargs='?',
                        help="The repository directory to get python packages."
                             "Default value is the cloned git repository path.")
    arguments = parser.parse_args()
    return arguments


def main(yaml_key, path, installation_mode):
    """
    Main function
    """
    # Access required value
    keys = yaml_key.split('.')

    build_yaml_file = os.path.join(path, 'env', 'cfg', keys[0],
                                   str(installation_mode), 'packages.yaml')

    # Parse file
    try:
        with open(build_yaml_file, 'r') as f:
            y = yaml.load(f)
    except:
        return None

    yaml_path = 'y'
    for key in keys:
       yaml_path += "['" + key + "']"

    # Write to standard output
    value = eval(yaml_path)
    if type(value) is list:
       # Print lists removing python syntax, i.e. [a, b, c]
       for v in value:
          print v
    else:
       print value


if __name__ == '__main__':
    ARGS = parse_arguments()
    main(yaml_key=ARGS.yaml_key,
         path=ARGS.project_path,
         installation_mode=ARGS.installation_mode)


