#!/bin/bash

(nc -z localhost 8081 && nc -z localhost 8188 && nc -z localhost 4222 && nc -z localhost "$NEXTCLOUD_TALK_TURN_PORT") || exit 1
