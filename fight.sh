#!/bin/bash

export GOPATH="$(pwd)"

rm -f *.log
rm -f *.hlt

#./halite -q -d "30 30" "go run jc02/main.go" "go run jc03/main.go" "go run jc04/main.go"
./halite -q -d "30 30" "go run jc03/main.go" "go run jc04/main.go"
