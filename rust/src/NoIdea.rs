#![allow(non_snake_case)]
#![allow(warnings)]

extern crate rand;
#[macro_use]
extern crate text_io;

// Notice: due to Rust's extreme dislike of (even private!) global mutables, we do not reset the production values of each tile during get_frame.
// If you change them, you may not be able to recover the actual production values of the map, so we recommend not editing them.
// However, if your code calls for it, you're welcome to edit the production values of the sites of the map - just do so at your own risk.

mod hlt;
use hlt::{networking, types};
use std::collections::HashMap;
use rand::Rng;

fn main() {
    let (my_id, mut game_map) = networking::get_init();
    networking::send_init(format!("{}{}", "NoIdea".to_string(), my_id.to_string()));
    loop {
        networking::get_frame(&mut game_map);
        let mut moves = HashMap::new();
        for a in 0..game_map.height {
            for b in 0..game_map.width {
                let loc = types::Location { x: b, y: a };
                let site = game_map.get_site(loc, types::STILL);
                if site.owner == my_id {
                    moves.insert(loc, move_cell(loc));
                }
            }
        }
        networking::send_frame(moves);
    }
}

fn move_cell(loc: types::Location) -> u8 {
    let cardinals = types::CARDINALS;
    let result = cardinals.into_iter()
        .filter(|&&dir| dir == 2);

    let mut rng = rand::thread_rng();
    (rng.gen::<u32>() % 5) as u8
}
