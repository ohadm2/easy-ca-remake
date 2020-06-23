#!/bin/bash
# Derek Moore <derek.moore@gmail.com>

usage() {
    echo "Usage: $0 -c CA_DIR -s SERVER_NAME [-a ALT_NAME]..."
    echo "Issues a server certificate for SERVER_NAME"
    echo
    echo "Options:"
    echo "    -c CA_DIR  the CA or SubCA dir to sign the client cert with"    
    echo "    -s SERVER_NAME  Server hostname (commonName) for the new cert"
    echo "    -a ALT_NAME     One (or more) subjectAltNames for the new cert (optional)"
    echo
    exit 2
}

CA_DIR=
SERVER_NAME=
ALT_NAME=

while getopts s:a:c: FLAG; do
    case $FLAG in
        s) SERVER_NAME=${OPTARG}
           if [ -z "${ALT_NAME}" ]; then
               ALT_NAME="DNS:${OPTARG}"
           else
               ALT_NAME="${ALT_NAME}, DNS:${OPTARG}"
           fi
           ;;
        a) if [ -z "${ALT_NAME}" ]; then
               ALT_NAME="DNS:${OPTARG}"
           else
               ALT_NAME="${ALT_NAME}, DNS:${OPTARG}"
           fi
           ;;
        c) CA_DIR=${OPTARG} 
            ;;
        *) usage
           ;;
    esac
done

if [ "${SERVER_NAME}" == "" -o "${CA_DIR}" == "" ]; then
    usage
fi


BIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${BIN_DIR}/functions
source ${BIN_DIR}/defaults.conf

# Sanitize the commonName to make it suitable for use in filenames
SAFE_NAME=`echo ${SERVER_NAME} | sed 's/\*/star/g'`
SAFE_NAME=`echo ${SAFE_NAME} | sed 's/[^A-Za-z0-9-]/-/g'`

if ! [ -f ${CA_DIR}/conf/ca.conf ]; then
    echo "Error! Could not find a valid ca at '${CA_DIR}'!"
    echo "Aborting!"
    
    exit 1
else
    cd ${CA_DIR}	
fi

echo
echo "Creating new SSL server certificate for:"
echo "commonName: ${SERVER_NAME}"
echo "subjectAltName: ${ALT_NAME}"
echo

pushd -n ${BIN_DIR}/.. > /dev/null

if [ -f conf/${SAFE_NAME}.server.conf ]; then
    echo "Configuration already exists for '${SERVER_NAME}', exiting."
    exit 1
fi

echo -n "Enter passphase for signing CA key: "
read -s PASS
echo
export CA_PASS=${PASS}

# Generate the server openssl config
export CA_HOSTNAME=${SERVER_NAME}
export SAN=${ALT_NAME}
template "${BIN_DIR}/templates/server.tpl" "conf/${SAFE_NAME}.server.conf"

# Create the server key and csr
openssl req -new -nodes \
            -config conf/${SAFE_NAME}.server.conf \
            -keyout private/${SAFE_NAME}.server.key \
            -out csr/${SAFE_NAME}.server.csr
chmod 0400 private/${SAFE_NAME}.server.key

# Create the server certificate
openssl ca -batch -notext \
           -config conf/ca.conf \
           -in csr/${SAFE_NAME}.server.csr \
           -out certs/${SAFE_NAME}.server.crt \
           -days 730 \
           -extensions server_ext \
           -passin env:CA_PASS

#popd > /dev/null

echo
echo "Server certificate created."
echo

