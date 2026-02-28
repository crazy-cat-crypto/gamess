# Under The Surface - Simple Godot MVP

A very small 2D mining prototype for the theme **UNDER THE SURFACE**.

## What is included

- Side-view 2D underground world (block grid).
- Move + jump player controller.
- Mine nearby blocks with left click.
- Oxygen drains underground and refills at the surface.
- Collect 10 shards underground, then return to surface to win.
- Lose if oxygen reaches 0.

## Open and run

1. Open this folder in Godot 4.x.
2. Let Godot import the project.
3. Run the main scene (`scenes/main.tscn`) or run the project.

## Controls

- Move: Arrow Left / Arrow Right
- Jump: Arrow Up
- Mine: Left mouse button (within short reach)
- Restart after win/lose: `R`

## Project structure

- `project.godot`
- `scenes/main.tscn`
- `scenes/player.tscn`
- `scenes/block.tscn`
- `scenes/shard.tscn`
- `scripts/main.gd`
- `scripts/player.gd`
- `scripts/block.gd`
- `scripts/shard.gd`

## Keep this simple first

For jam speed, this MVP intentionally avoids crafting, enemies, inventory UI, and procedural polish. Once this base feels good, add one feature at a time.