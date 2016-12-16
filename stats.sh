#!/bin/bash

export GOPATH="$(pwd)/golang"

rm -f *.log
rm -f *.hlt
rm -f */*.log
rm -f */*.hlt

go run stats.go 4 8 'cd golang;go run jc03/main.go' 'cd golang;go run jc05/main.go' 'cd ruby;ruby jc03.rb'
