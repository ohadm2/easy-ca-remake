# easy-ca-remake
OpenSSL wrapper scripts for managing basic CA functions (based on https://github.com/redredgroovy/easy-ca)

Prerequisites:
-----------------------

* OpenSSL
* Bash scripts support (Linux or Cygwin [or similar] on Windows)

Main scripts Explained:
-----------------------

create-root-ca.sh - create a local CA.

create-sub-ca.sh - create a Sub CA connected to the CA above.

create-client-cert.sh - create a certificate for a client (of client authentication type) using the above CAs chain.

create-server-cert.sh - create a certificate for a server (of server authentication type) using the above CAs chain.

pem-and-key-to-pfx.sh - convert the created end certificates (of client or server) from a pem and key style cert to a pfx cert format (to use in Windows for example).