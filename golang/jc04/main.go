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
	conn, gameMap = hlt.NewConnection("JC04")

	for {
		var moves hlt.MoveSet
		gameMap = conn.GetFrame()

		// go through all locations
		for y := 0; y < gameMap.Height; y++ {
			for x := 0; x < gameMap.Width; x++ {

				loc := hlt.NewLocation(x, y)
				// is it my cell? if so then let's see what we can do with it
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
	still := hlt.Move{Location: loc, Direction: hlt.STILL}

	// choose good targets first
	if move := target(loc); move != nil {
		return *move
	}

	// wait to gather strength
	if site.Strength < site.Production*5 {
		return still
	}

	// does a cell around me need help?
	if move := help(loc); move != nil {
		return *move
	}

	// lets go to the nearest border
	if !border(loc) {
		return hlt.Move{
			Location:  loc,
			Direction: nearestBorderDir(loc),
		}
	}

	// can't attack, hold still
	return still
}

func nearestBorderDir(loc hlt.Location) hlt.Direction {
	dir := hlt.NORTH
	maxDistance := int(math.Min(float64(gameMap.Width), float64(gameMap.Height))) / 2

	// find nearest border horizontal/vertical
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
			// move 1 step into direction 'd'
			currLoc = gameMap.GetLocation(currLoc, d)
			site = gameMap.GetSite(currLoc, hlt.STILL)
		}

		// is it closer than previous border?
		if distance < maxDistance {
			dir = d
			maxDistance = distance
		}
	}
	return dir
}

func target(loc hlt.Location) *hlt.Move {
	site := gameMap.GetSite(loc, hlt.STILL)

	var found bool
	var targetSite hlt.Site
	var targetDir hlt.Direction
	value := -1.0

	for _, d := range hlt.CARDINALS {
		target := gameMap.GetSite(loc, d)
		if target.Owner != conn.PlayerTag {
			// eval target value
			v := float64(target.Production)
			if target.Strength > 0 {
				v = float64(target.Production) / float64(target.Strength)
			}

			// find best target
			if v > value {
				targetDir = d
				targetSite = target
				value = v
				found = true
			}
		}
	}

	// if good target found and cell is strong enough to attack, then do it!
	if found &&
		(targetSite.Strength < site.Strength ||
			(targetSite.Strength == site.Strength && site.Strength >= 250)) {
		return &hlt.Move{
			Location:  loc,
			Direction: targetDir,
		}
	}
	return nil
}

func help(loc hlt.Location) *hlt.Move {
	site := gameMap.GetSite(loc, hlt.STILL)

	// does a cell around me need help?
	for _, dir := range hlt.CARDINALS {
		cell := gameMap.GetSite(loc, dir)
		if cell.Owner == conn.PlayerTag {
			// is it at border?
			cellLoc := gameMap.GetLocation(loc, dir)
			if border(cellLoc) {
				if cell.Strength > site.Strength && // weaker cells should reinforce stronger ones
					cell.Strength+site.Strength <= 260 { // but only if not overflowing strength
					return &hlt.Move{
						Location:  loc,
						Direction: dir,
					}
				}
			}
		}
	}
	return nil
}

func border(loc hlt.Location) bool {
	for _, d := range hlt.CARDINALS {
		target := gameMap.GetSite(loc, d)
		// bordering enemy cell?
		if target.Owner != conn.PlayerTag {
			return true
		}
	}
	return false
}
