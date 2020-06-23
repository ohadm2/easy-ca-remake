#!/bin/bash
# Derek Moore <derek.moore@gmail.com>

usage() {
    echo "Usage: $0 -s SUBCA_DIR -c ROOT_CA_DIR"
    echo "Initializes a new signing sub-CA in SUBCA_DIR"
    echo
    echo "Options:"
    echo "    -s SUBCA_DIR  Target directory to be created and initialized"
    echo "    -c ROOT_CA_DIR  the parent CA (root ca) to connect the new sub ca to"
    echo
    exit 2
}

SUBCA_DIR=
ROOT_CA_DIR=

while getopts s:c: OPTION; do
    case $OPTION in
        s) SUBCA_DIR=${OPTARG} ;;
        c) ROOT_CA_DIR=${OPTARG} ;;        
        *) usage ;;
    esac
done

if [ "${SUBCA_DIR}" == "" -o "${ROOT_CA_DIR}" == "" ]; then
    usage
fi

if ! [ -f ${ROOT_CA_DIR}/conf/ca.conf ]; then
    echo "Error! Could not find a valid ca at '${ROOT_CA_DIR}'!"
    echo "Aborting!"
    
    exit 1
fi

BIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${BIN_DIR}/functions
source ${BIN_DIR}/defaults.conf

HOME=$SUBCA_DIR
PARENT=${BIN_DIR}/..
CA_NAME=$( basename "${HOME}" )

echo
echo "Creating new signing sub-CA in '${HOME}'"
echo

init_ca_home ${HOME}
generate_conf ${HOME}/bin/defaults.conf yes
source ${HOME}/bin/defaults.conf

echo
echo -n "Enter passphase for encrypting signing CA key: "
read -s PASS1
echo
echo -n "Verifying - Enter passphase for encrypting signing CA key: "
read -s PASS2
echo

if [ "${PASS1}" != "${PASS2}" ]; then
    echo "Passphrases did not match, exiting."
    exit 1
fi
export CA_PASS=${PASS1}

echo

echo -n "Enter passphase for root CA key: "
read -s PARENT_PASS
echo
export CA_PARENT_PASS=${PARENT_PASS}

pushd . > /dev/null

# Fully-qualify home so we can return to it later
HOME=$( cd "${HOME}" && pwd )

pushd ${HOME} > /dev/null

echo
echo Generate the signing CA openssl config
echo --------------------------------------------

# for the template to be updated ...
#CA_ROOT_DIR=`realpath ${SUBCA_DIR}`

template "${BIN_DIR}/templates/sub-ca.tpl" "conf/ca.conf"

echo
echo Create the signing CA key
echo --------------------------------------------

openssl genrsa -out ca/private/ca.key -passout env:CA_PASS 2048
chmod 0400 ca/private/ca.key

echo
echo Create the signing CA csr
echo --------------------------------------------

openssl req -new -batch \
            -config conf/ca.conf \
            -key ca/private/ca.key \
            -out ca/ca.csr \
            -passin env:CA_PASS

echo Create the signing CA certificate
echo --------------------------------------------

#pushd -n ${PARENT} > /dev/null

echo SAN=$SAN

popd 

cd "$ROOT_CA_DIR"

openssl ca -batch -notext -config conf/ca.conf \
           -in ${HOME}/ca/ca.csr \
           -out ca/root-for-subca.crt \
           -days 3652 \
           -extensions signing_ca_ext \
           -passin env:CA_PARENT_PASS

#popd > /dev/null

echo
echo Create the chain bundle for the sub-CA
echo --------------------------------------------

cat ca/ca.crt ca/root-for-subca.crt >> ${HOME}/ca/subCa_chain.crt

cp ca/root-for-subca.crt ${HOME}/ca/ca.crt


echo
echo Create the signing CRL
echo --------------------------------------------

openssl ca -gencrl -batch \
           -config conf/ca.conf \
           -out crl/ca.crl


for BIN in ${BINARIES}; do
    cp ${BIN_DIR}/${BIN} bin/
done

cp -r ${BIN_DIR}/templates bin/

#popd > /dev/null

echo
echo "Signing sub-CA initialized."
echo

