#!/bin/bash
i3-msg "rename workspace to \"$(rofi -dmenu -lines 0 -p 'New name')\""
