#!/bin/bash
# 

usage() {
    echo "Usage: $0 -p CERT -k KEY -o PFX"
    echo "Converts a cert and key to pfx."
    echo
    echo "Options:"
    echo "    -p CERT  the public part of the cert (pem file / crt file etc.)"
    echo "    -k KEY  the private part of the cert (key file)"
    echo "    -o PFX  a name for the pfx file to create (just a name)"
    echo
    exit 2
}

CERT=
KEY=
PFX=

while getopts 'p:k:o:' OPTION; do
    case $OPTION in
        p) CERT=${OPTARG} ;;
        k) KEY=${OPTARG} ;;
        o) PFX=${OPTARG} ;;
        *) usage ;;
    esac
done

if [ "${CERT}" == "" -o "${KEY}" == "" -o "${PFX}" == "" ]; then
    usage
fi

openssl pkcs12 -in ${CERT} -inkey ${KEY} -export -out ${PFX}.pfx
