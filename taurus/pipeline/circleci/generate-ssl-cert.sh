  #!/bin/bash
# ----------------------------------------------------------------------
# Numenta Platform for Intelligent Computing (NuPIC)
# Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
# Numenta, Inc. a separate commercial license for this software code, the
# following terms and conditions apply:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero Public License for more details.
#
# You should have received a copy of the GNU Affero Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# http://numenta.org/licenses/
# ----------------------------------------------------------------------
#
set -o errexit
set -o pipefail

subj=`echo "
C=US
ST=CA
O=Numenta, Inc.
localityName=Redwood City
commonName=numenta.com
organizationalUnitName=Engineering
emailAddress=devnull@numenta.com
" | sed -e 's/^[ \t]*//'`

PASSWD=`openssl passwd $RANDOM`

mkdir -p /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl

# Generate the server private key
openssl genrsa \
  -des3 \
  -out /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.key \
  -passout pass:${PASSWD} \
  1024

# Generate the CSR
openssl req \
    -new \
    -batch \
    -subj "$(echo -n "${subj}" | tr "\n" "/")" \
    -key /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.key \
    -out /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.csr \
    -passin pass:${PASSWD}
cp \
  /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.key \
  /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.key.bak

# Strip the password so we don't have to type it every time we restart nginx
openssl rsa \
  -in /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.key.bak \
  -out /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.key \
  -passin pass:${PASSWD}

# Generate the cert (good for 1 year)
openssl x509 \
  -req \
  -days 365 \
  -in /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.csr \
  -signkey /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.key \
  -out /home/ubuntu/numenta-apps/taurus/pipeline/circleci/ssl/localhost.crt
