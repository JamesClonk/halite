package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
)

var (
	wins  map[string]int
	wg    sync.WaitGroup
	mutex = &sync.Mutex{}
)

func main() {
	if len(os.Args) < 5 {
		fmt.Println("usage: ./stats <iterations> <workers> <bot1> <bot2> [<bot3>...]")
		os.Exit(1)
	}

	iterations, err := strconv.ParseInt(os.Args[1], 10, 64)
	if err != nil {
		panic(err)
	}

	workers, err := strconv.ParseInt(os.Args[2], 10, 64)
	if err != nil {
		panic(err)
	}

	bots := os.Args[3:]
	wins = make(map[string]int, 0)
	battles := make(chan []string, 0)

	for w := 1; w <= int(workers); w++ {
		go simulate(battles)
	}

	for ; iterations > 0; iterations-- {
		for i := range bots {
			for j := range bots {
				if i == j {
					continue
				}
				wg.Add(1)
				battles <- []string{bots[i], bots[j]}
			}
		}
	}
	close(battles)
	wg.Wait()
	deleteFiles()

	fmt.Println()
	for bot, win := range wins {
		fmt.Printf("Bot [%s] won [%d] times\n", bot, win)
	}
}

func simulate(battles <-chan []string) {
	for battle := range battles {
		blue := battle[0]
		red := battle[1]
		command := []string{"./halite", "-t", "-q", "-d", "30 30", blue, red}
		log.Println(command)
		cmd := exec.Command(command[0], command[1:]...)
		output, err := cmd.CombinedOutput()
		if err != nil {
			panic(err)
		}
		lines := strings.SplitN(string(output), "\n", 6)
		result := strings.SplitN(lines[3], " ", 3)

		mutex.Lock()
		if result[1] == "1" {
			wins[blue] += 1
		} else {
			wins[red] += 1
		}
		mutex.Unlock()

		wg.Done()
	}
}

func deleteFiles() {
	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if info.IsDir() {
			return nil
		}
		if filepath.Ext(path) == ".hlt" {
			return os.Remove(path)
		} else if filepath.Ext(path) == ".log" {
			return os.Remove(path)
		}
		return nil
	})
	if err != nil {
		panic(err)
	}
}
