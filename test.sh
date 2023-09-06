#!/usr/bin/bash

godot --path . --server &
sleep .2
godot --path . --auto-join &
godot --path . --auto-join &

