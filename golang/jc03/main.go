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
	conn, gameMap = hlt.NewConnection("JC03")

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

	// go to productive targets
	do, dir, target := getProductiveTarget(loc)
	if do &&
		(target.Strength < site.Strength ||
			(target.Strength == site.Strength && site.Strength >= 250)) {
		return hlt.Move{
			Location:  loc,
			Direction: dir,
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
	if !isAtBorder(loc) {
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
				distance >= maxDistance {
				break
			}

			distance++
			currLoc = gameMap.GetLocation(currLoc, d) // move 1 step into direction 'd'
			site = gameMap.GetSite(currLoc, hlt.STILL)
		}

		if distance < maxDistance {
			dir = d
			maxDistance = distance
		}
	}
	return dir
}

func getProductiveTarget(loc hlt.Location) (bool, hlt.Direction, hlt.Site) {
	var ok bool
	var targetSite hlt.Site
	var targetDir hlt.Direction
	value := -1.0

	for _, d := range hlt.CARDINALS {
		target := gameMap.GetSite(loc, d)
		if target.Owner != conn.PlayerTag {
			v := float64(target.Production)
			if target.Strength > 0 {
				v = float64(target.Production) / float64(target.Strength)
			}

			if v > value {
				targetDir = d
				targetSite = target
				value = v
				ok = true
			}
		}
	}
	return ok, targetDir, targetSite
}

func isAtBorder(loc hlt.Location) bool {
	for _, d := range hlt.CARDINALS {
		target := gameMap.GetSite(loc, d)
		// bordering enemy cell?
		if target.Owner != conn.PlayerTag {
			return true
		}
	}
	return false
}
