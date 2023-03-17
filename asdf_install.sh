#!/bin/bash

set -eu

asdf_version=v0.11.3

## The existing directory is not updated or overwritten.

if ! [[ -d ${asdf_dir} ]]; then
  git clone https://github.com/asdf-vm/asdf.git ${asdf_dir} --branch ${asdf_version} --quiet -c advice.detachedHead=false
fi

ASDF_DATA_DIR=$(realpath "${asdf_dir}")
export ASDF_DATA_DIR
. ${asdf_dir}/asdf.sh

## Some plugins like awscli don't work with multiple asdf instances
## then the trick is to run plugin from separate current directory.

cd ${asdf_dir}

for plugin in ${asdf_tools}; do
  asdf plugin add ${plugin} || test $? = 2
  asdf install ${plugin}
done
