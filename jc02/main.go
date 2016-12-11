package main

import (
	"hlt"
	"math"
	"math/rand"
	"time"
)

var (
	conn    hlt.Connection
	gameMap hlt.GameMap
)

func main() {
	rand.Seed(time.Now().UTC().UnixNano())
	conn, gameMap = hlt.NewConnection("JC02")

	for {
		var moves hlt.MoveSet
		gameMap = conn.GetFrame()

		for y := 0; y < gameMap.Height; y++ {
			for x := 0; x < gameMap.Width; x++ {

				loc := hlt.NewLocation(x, y)
				if gameMap.GetSite(loc, hlt.STILL).Owner == conn.PlayerTag {
					moves = append(moves, move(loc))
				}
			}
		}

		conn.SendFrame(moves)
	}
}

func move(loc hlt.Location) hlt.Move {
	site := gameMap.GetSite(loc, hlt.STILL)
	border := false

	// check in all directions
	for _, d := range hlt.CARDINALS {
		target := gameMap.GetSite(loc, d)
		// bordering enemy cell?
		if target.Owner != conn.PlayerTag {
			border = true
			// attack if weaker
			if target.Strength < site.Strength {
				return hlt.Move{
					Location:  loc,
					Direction: d,
				}
			}
		}
	}

	// wait to gather strength
	if site.Strength < site.Production*5 {
		return hlt.Move{
			Location:  loc,
			Direction: hlt.STILL,
		}
	}

	// lets go to the nearest border
	if !border {
		return hlt.Move{
			Location:  loc,
			Direction: getNearestBorderDirection(loc),
		}
	}

	// can't attack, hold still
	return hlt.Move{
		Location:  loc,
		Direction: hlt.STILL,
	}
}

func getNearestBorderDirection(loc hlt.Location) hlt.Direction {
	dir := hlt.NORTH
	maxDistance := int(math.Min(float64(gameMap.Width), float64(gameMap.Height))) / 2

	for _, d := range hlt.CARDINALS {
		distance := 0
		currLoc := loc
		site := gameMap.GetSite(currLoc, d)

		for {
			if site.Owner != conn.PlayerTag ||
				distance > maxDistance {
				break
			}

			distance++
			currLoc = gameMap.GetLocation(currLoc, d) // move 1 step into direction 'd'
			site = gameMap.GetSite(currLoc, d)
		}

		if distance < maxDistance {
			dir = d
			maxDistance = distance
		}
	}
	return dir
}
