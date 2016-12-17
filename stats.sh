#!/bin/bash

export GOPATH="$(pwd)/golang"

rm -f *.log
rm -f *.hlt
rm -f */*.log
rm -f */*.hlt

#go run stats.go 10 8 'cd golang;go run jc04/main.go' 'cd ruby;ruby jc03_mk2.rb' 'cd ruby;ruby jc04_mk2.rb'
go run stats.go 25 8 'cd ruby;ruby jc06_mk2.rb' 'cd ruby;ruby jc07.rb'
#go run stats.go 10 8 'cd golang;go run jc04/main.go' 'cd ruby;ruby jc06.rb'
