#!/bin/bash
set -e -o pipefail

# Run confd to render config file(s)
confd -onetime -backend env

# Run application
exec "$@" | tee /packer/build.log