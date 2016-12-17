#!/bin/bash

export GOPATH="$(pwd)/golang"

rm -f *.log
rm -f *.hlt
rm -f */*.log
rm -f */*.hlt

./halite -q -d "30 30" 'cd golang;go run jc04/main.go' 'cd golang;go run jc05/main.go' 'cd ruby;ruby jc03.rb' 'cd ruby;ruby jc03_mk2.rb' 'cd ruby;ruby jc04_mk2.rb'  'cd ruby;ruby jc06.rb'

if [[ -d ~/00_VM_SHARE/ ]]; then
	rm -f ~/00_VM_SHARE/*.hlt
	cp *.hlt ~/00_VM_SHARE/.
fi
