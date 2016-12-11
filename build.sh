#!/bin/bash

rm -rf output/*
mkdir -p output/src/hlt
cp -R src/hlt/* output/src/hlt/.
cp $1/main.go output/MyBot.go
cp install.sh output/.
chmod +x output/install.sh

pushd output
zip MyBot *
zip MyBot */*/*
popd
