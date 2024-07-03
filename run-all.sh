#!/bin/bash

cd $(dirname ${BASH_SOURCE[0]})

./create-root-ca.sh -c root-ca
./create-sub-ca.sh -c root-ca -s sub-ca
./create-server-cert.sh -c sub-ca -s my.site.local -a my.site.local


