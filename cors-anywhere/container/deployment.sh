#!/usr/bin/env bash
exec 2>&1
set -e
set -x

npm install cors-anywhere
cd /node_modules/cors-anywhere
npm install

