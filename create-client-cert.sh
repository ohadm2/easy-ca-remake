#!/bin/bash
# Derek Moore <derek.moore@gmail.com>

usage() {
    echo "Usage: $0 -n CLIENT_NAME -c CA_DIR"
    echo "Issues a client certificate for CLIENT_NAME"
    echo
    echo "Options:"
    echo "    -n CLIENT_NAME  Client name (commonName) for the new cert"
    echo "    -c CA_DIR  the CA or SubCA dir to sign the client cert with"
    echo
    exit 2
}

CLIENT_NAME=
CA_DIR=

while getopts 'n:c:' OPTION; do
    case $OPTION in
        n) CLIENT_NAME=${OPTARG} ;;
        c) CA_DIR=${OPTARG} ;;
        *) usage ;;
    esac
done

if [ "${CLIENT_NAME}" == "" -o "${CA_DIR}" == "" ]; then
    usage
fi

BIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source ${BIN_DIR}/functions
source ${BIN_DIR}/defaults.conf

SAFE_NAME=`echo $CLIENT_NAME | sed 's/\*/star/g'`
SAFE_NAME=`echo $SAFE_NAME | sed 's/[^A-Za-z0-9-]/-/g'`

if ! [ -f ${CA_DIR}/conf/ca.conf ]; then
    echo "Error! Could not find a valid ca at '${CA_DIR}'!"
    echo "Aborting!"
    
    exit 1
else
    cd ${CA_DIR}
fi

echo
echo "Creating new client certificate for '${CLIENT_NAME}'"
echo

pushd -n ${BIN_DIR}/.. > /dev/null

if [ -f conf/${SAFE_NAME}.client.conf ]; then
    echo "Configuration already exists for '${CLIENT_NAME}', exiting."
    exit 1
fi

echo -n "Enter passphase for signing CA key: "
read -s PASS
echo
export CA_PASS=${PASS}

# Generate the client cert openssl config
export SAN=""
export CA_USERNAME=${CLIENT_NAME}

template "${BIN_DIR}/templates/client.tpl" "conf/${SAFE_NAME}.client.conf"

# Create the client key and csr
openssl req -new -nodes \
            -config conf/${SAFE_NAME}.client.conf \
            -keyout private/${SAFE_NAME}.client.key \
            -out csr/${SAFE_NAME}.client.csr

chmod 0400 private/${SAFE_NAME}.client.key

# Create the client certificate
openssl ca -batch -notext \
           -config conf/ca.conf \
           -in csr/${SAFE_NAME}.client.csr \
           -out certs/${SAFE_NAME}.client.crt \
           -days 730 \
           -extensions client_ext \
           -passin env:CA_PASS

#popd > /dev/null

echo
echo "Client certificate created."
echo

