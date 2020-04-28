#!/bin/bash

/etc/periodic/weekly/cert.sh
crond -l 2 -f