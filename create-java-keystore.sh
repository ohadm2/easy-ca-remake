#!/bin/bash

cd $(dirname ${BASH_SOURCE[0]})

openssl pkcs12 -export -in sub-ca/certs/my-site-local.server.crt -inkey sub-ca/private/my-site-local.server.key -certfile sub-ca/ca/subCa_chain.crt -out keystore.p12 -name tomcat -password pass:changeit
