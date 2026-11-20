#!/usr/bin/env bash

conky --daemonize --pause=5 -c /home/jim/.config/conky/conky-logs.conf &
conky --daemonize --pause=5 &
conky --daemonize --pause=5 -c /home/jim/.config/conky/weather.conf &
