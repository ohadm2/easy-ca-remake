#!/bin/bash
# Derek Moore <derek.moore@gmail.com>

usage() {
    echo "Usage: $0 -c CA_DIR"
    echo "Initializes a new root CA in CA_DIR"
    echo
    echo "Options:"
    echo "    -c CA_DIR  Target directory to be created and initialized"
    echo
    exit 2
}

CA_DIR=

while getopts c: FLAG; do
    case $FLAG in
        c) CA_DIR=${OPTARG} ;;
        *) usage ;;
    esac
done

if [ "${CA_DIR}" == "" ]; then
    usage
fi

BIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source ${BIN_DIR}/functions

[[ -f "${BIN_DIR}/defaults.conf" ]] && source ${BIN_DIR}/defaults.conf

HOME=$CA_DIR
CA_NAME=$( basename "${HOME}" )

echo
echo "Creating root CA in '${HOME}'"
echo

init_ca_home ${HOME}
generate_conf ${HOME}/bin/defaults.conf
source ${HOME}/bin/defaults.conf

echo
echo -n "Enter passphase for encrypting root CA key: "
read -s PASS1
echo
echo -n "Verifying - Enter passphase for encrypting root CA key: "
read -s PASS2
echo

if [ "${PASS1}" != "${PASS2}" ]; then
    echo "Passphrases did not match, exiting."
    exit 1
fi
export CA_PASS=${PASS1}

pushd ${HOME} > /dev/null


echo
echo Generate the signing CA openssl config
echo --------------------------------------------

# Generate the root CA openssl config
template "${BIN_DIR}/templates/root-ca.tpl" "conf/ca.conf"


# for the template to be updated ...
#CA_ROOT_DIR=`realpath ${CA_DIR}`

echo
echo Create the signing CA key
echo --------------------------------------------

# Create the root CA csr
openssl genrsa -out ca/private/ca.key -passout env:CA_PASS 4096
chmod 0400 ca/private/ca.key

echo
echo Create the signing CA csr
echo --------------------------------------------

# Create the root CA csr
openssl req -new -batch \
            -config conf/ca.conf \
            -key ca/private/ca.key \
            -out ca/ca.csr \
            -passin env:CA_PASS

echo Create the signing CA certificate
echo --------------------------------------------

# Create the root CA certificate
openssl ca -selfsign -batch -notext \
           -config conf/ca.conf \
           -in ca/ca.csr \
           -out ca/ca.crt \
           -days 3652 \
           -extensions root_ca_ext \
           -passin env:CA_PASS

# Create the root CRL
openssl ca -gencrl -batch \
           -config conf/ca.conf \
           -out crl/ca.crl

# Replicate the existing binary directory
for BIN in ${BINARIES}; do
    cp ${BIN_DIR}/${BIN} bin/
done
cp -r ${BIN_DIR}/templates bin/

popd > /dev/null

echo
echo "Root CA initialized."
echo

