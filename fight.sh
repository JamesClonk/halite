#!/bin/bash

export GOPATH="$(pwd)/golang"

rm -f *.log
rm -f *.hlt
rm -f */*.log
rm -f */*.hlt

./halite -t -q -d "30 30" 'cd golang;go run jc03/main.go' 'cd golang;go run jc05/main.go' 'cd ruby;ruby jc03.rb'

if [[ -d ~/00_VM_SHARE/ ]]; then
	rm -f ~/00_VM_SHARE/*.hlt
	cp *.hlt ~/00_VM_SHARE/.
fi
