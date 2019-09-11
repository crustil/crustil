#!/usr/bin/env bash

set -e

health-agent &

nginx -g "daemon off;"