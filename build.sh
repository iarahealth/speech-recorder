#!/bin/bash

set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "$HERE" &> /dev/null

if [[ -z "$1" ]] ; then
  echo "Usage: build.sh x86|x64|arm64 [napi-version] [github-token]"
  exit 1
fi

napi_version="${2:-6}"

rm -rf lib/build lib/install
mkdir -p lib/build
cd lib/build

if [[ `uname -s` == "MINGW"* ]] ; then
  if [[ "$1" == "x86" ]] ; then
    cmake -A Win32 ..
  elif [[ "$1" == "x64" ]] ; then
    cmake -A x64 ..
  fi
elif [[ `uname -s` == "Darwin" ]] ; then
  if [[ "$1" == "x64" ]] ; then
    cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 ..
  elif [[ "$1" == "arm64" ]] ; then
    cmake -DCMAKE_OSX_ARCHITECTURES=arm64 ..
  fi
else
  cmake ..
fi

if [[ `uname -s` == "MINGW"* ]] ; then
  cmake --build . --config RelWithDebInfo
  mv RelWithDebInfo Release
else
  cmake --build . --config Release
fi
cmake --install . --prefix ../install

cd ../..
rm -rf prebuilds

node_arch="$1"
if [[ "$1" == "x86" ]] ; then
  node_arch="ia32"
fi

eval "npm_config_arch=$node_arch ./node_modules/.bin/node-gyp rebuild"

prebuild_command="./node_modules/.bin/prebuild -r napi -t $napi_version --include-regex '.(node|a|dylib|dll|so.*)$' --arch=$node_arch"
if [[ -n "$3" ]] ; then
  prebuild_command+=" --upload $3"
fi
eval $prebuild_command

popd &> /dev/null
