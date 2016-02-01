#!/bin/bash
# ----------------------------------------------------------------------
# Numenta Platform for Intelligent Computing (NuPIC)
# Copyright (C) 2016, Numenta, Inc.  Unless you have purchased from
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


# This script will create a portable python distribution with
# nupic and nupic.bindings installed.

set -o errexit

OSX_VERSION=$(sw_vers -productVersion | awk -F '.' '{print $1 "." $2}')
echo "==> System version: $OSX_VERSION"
CWD=$(pwd)
PYTHON_SH="Miniconda-latest-MacOSX-x86_64.sh"
CAPNP="capnproto-c++-0.5.3"
NUPIC_CORE=${CWD}/nupic.core
NUPIC=${CWD}/nupic
PREFIX=${CWD}/miniconda
PATH_VALUE=${PREFIX}/bin:${PREFIX}/include

echo "==> Current working directory: $CWD"
echo "==> Python will be installed in: $PREFIX"
echo "==> Setting up environment variables ..."
# The env variable PATH has to be extended otherwise 
# nupic.bindings won't be installed properly.
export PATH=$PATH_VALUE:$PATH
echo "--> PATH: $PATH"

echo "==> Cleaning up ..."
rm $PYTHON_SH
echo "--> Removed: $PYTHON_SH"
rm -rf $PREFIX
echo "--> Removed: $PREFIX"
rm -rf $CAPNP
echo "--> Removed: $CAPNP"
rm $CAPNP.tar.gz
echo "--> Removed: $CAPNP.tar.gz"
rm -rf $NUPIC_CORE
echo "--> Removed: $NUPIC_CORE"
rm -rf $NUPIC
echo "--> Removed: $NUPIC"

echo "==> Downloading Miniconda ..."
curl -O https://repo.continuum.io/miniconda/$PYTHON_SH

echo "==> Installing Miniconda ..."
bash $PYTHON_SH -b -p $PREFIX

echo "==> Downloading Capnp ..."
curl -O https://capnproto.org/$CAPNP.tar.gz

echo "==> Installing Capnp ..."
tar zxf $CAPNP.tar.gz 
cd $CAPNP
./configure --disable-shared --prefix=$PREFIX
make -j6 check && make install
cd $CWD

echo "==> Cloning nupic.core ..."
git clone https://github.com/numenta/nupic.core.git

echo "==> Installing nupic.core requirements ..."
rm -rf $NUPIC_CORE/build
mkdir -p $NUPIC_CORE/build/scripts
$PREFIX/bin/pip install -r $NUPIC_CORE/bindings/py/requirements.txt
# Install pycapnp since it is not in nupic.core requirements.txt.
# Note: to install pycapnpn on Yosemite you have to set MACOSX_DEPLOYMENT_TARGET.
# More on this issue: https://github.com/numenta/nupic/issues/2061
export MACOSX_DEPLOYMENT_TARGET=$OSX_VERSION 
$PREFIX/bin/pip install pycapnp

echo "==> Building nupic.core ..."
cd $NUPIC_CORE/build/scripts
BUILD_CMD="cmake $NUPIC_CORE -DCMAKE_INCLUDE_PATH=${PREFIX}/include -DCMAKE_LIBRARY_PATH=${PREFIX}/lib -DCMAKE_PREFIX_PATH=${PREFIX} -DCMAKE_INSTALL_PREFIX=${PREFIX} -DPY_EXTENSIONS_DIR=${NUPIC_CORE}/bindings/py/nupic/bindings -DPYTHON_EXECUTABLE:FILEPATH=${PREFIX}/bin/python2.7 -DPYTHON_INCLUDE_DIR:PATH=${PREFIX}/include/2.7 -DPYTHON_LIBRARY:FILEPATH=${PREFIX}/lib/libpython2.7.dylib"
echo "--> Executing cmd: $BUILD_CMD"
$BUILD_CMD

echo "==> Installing nupic.core python bindings ..."
cd $NUPIC_CORE/bindings/py
export ARCHFLAGS="-arch x86_64"
$PREFIX/bin/python setup.py install

echo "==> Cloning nupic ..."
cd $CWD
git clone https://github.com/numenta/nupic.git

echo "==> Installing nupic ..."
cd $NUPIC
$PREFIX/bin/pip install -r external/common/requirements.txt
$PREFIX/bin/python setup.py install

echo "==> Cleaning up ..."
rm $PYTHON_SH
echo "--> Removed: $PYTHON_SH"
rm -rf ${CAPNP}*
echo "--> Removed: $CAPNP $CAPNP.tar.gz"
rm -rf $NUPIC_CORE
echo "--> Removed: $NUPIC_CORE"
rm -rf $NUPIC
echo "--> Removed: $NUPIC"

# Check that it worked
DYLD_LIBRARY_PATH=$PREFIX/lib $PREFIX/bin/python -c "import nupic.algorithms.anomaly_likelihood"
DYLD_LIBRARY_PATH=$PREFIX/lib $PREFIX/bin/python -c "import nupic.bindings.math"