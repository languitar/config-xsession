#!/usr/bin/env python3

import argparse
import sys

import i3

parser = argparse.ArgumentParser(
    description='Moves i3 items to outputs by cycling them '
                'independent of their position')
parser.add_argument('target', metavar='[container|workspace]',
                    help='Defines what to move. A container or a workspace.')
args = parser.parse_args()

outputs = i3.get_outputs()
workspaces = i3.get_workspaces()

# figure out what is on, and what is currently on your screen.
workspace = list(filter(lambda s: s['focused'] == True, workspaces))
output = list(filter(lambda s: s['active'] == True, outputs))

# figure out the other workspace name
other_workspace = list(filter(lambda s: s['name'] != workspace[0]['output'],
                              output))

# send current to the no-active one
i3.command('move', '{} to output {}'.format(args.target,
                                            other_workspace[0]['name']))
