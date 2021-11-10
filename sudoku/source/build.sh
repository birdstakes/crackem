#!/bin/sh
set -e

TCLKIT_URL='http://tclkits.rkeene.org/fossil/raw/tclkit-8.6.3-win32-x86_64.exe?name=403c507437d0b10035c7839f22f5bb806ec1f491'
TCLKITSH_URL='http://tclkits.rkeene.org/fossil/raw/tclkitsh-8.6.3-win32-x86_64.exe?name=3827d0c8fab8a88fad26b62bb1becae808ce6d5a'
SDX_URL='http://chiselapp.com/user/aspect/repository/sdx/uv/sdx-20110317.kit'
RESOURCE_HACKER_URL='http://www.angusj.com/resourcehacker/resource_hacker.zip'

if [ ! -d build ]; then
    mkdir build

    curl $TCLKIT_URL --output build/tclkit.exe
    curl $TCLKITSH_URL --output build/tclkitsh.exe
    curl $SDX_URL --output build/sdx.kit
    curl $RESOURCE_HACKER_URL --output build/resource_hacker.zip

    unzip build/resource_hacker.zip -d build/resource_hacker

    ./build/resource_hacker/ResourceHacker.exe \
        -open build/tclkit.exe \
        -save build/tclkit.exe \
        -action addoverwrite -res icon.ico -mask ICONGROUP,TK,

    ./build/resource_hacker/ResourceHacker.exe \
        -open build/tclkit.exe \
        -save build/tclkit.exe \
        -action delete -mask VERSIONINFO,,

    rm build/resource_hacker.zip
    rm -r build/resource_hacker
fi

rm -rf build/sudoku.vfs
mkdir build/sudoku.vfs

pushd src
find -name '*.tcl' -exec cp --parents '{}' ../build/sudoku.vfs/  ';'
popd

gcc -O3 -DUSE_TCL_STUBS -shared -o build/sudoku.vfs/lib/check/check.dll src/lib/check/check.c -ltclstub86

cd build
./tclkitsh sdx.kit wrap sudoku.exe -runtime tclkit.exe
