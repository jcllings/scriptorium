#!/usr/bin/env bash
systemctl status squid --no-pager

ps -aux | grep squid
