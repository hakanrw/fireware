#!/usr/bin/bash

godot --path . --server --auto-join &
sleep .2
godot --path . --auto-join &
godot --path . --auto-join &

