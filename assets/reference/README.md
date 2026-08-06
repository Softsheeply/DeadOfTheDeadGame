# Dead of the Dead

A living Day of the Dead world where the village continues to live even when the player does nothing.

## Vision
See /docs/vision.md

## Art Guide
See /docs/art_style.md

## Asset Pipeline
See /docs/asset_pipeline.md

## World Design
See /docs/world_design.md

## Roadmap
See /docs/roadmap.md

# 💀 Dead of the Dead

*A living Day of the Dead world where the village feels alive even when the player does nothing.*

---

# Vision

Dead of the Dead is **NOT** a survival game.

It is **NOT** an RPG first.

It is **NOT** an idle game.

It is a **living world simulator** inspired by games like:

- Pocket God
- Animal Crossing
- Stardew Valley
- Cozy Grove

The goal is to create a world that players enjoy simply watching.

---

# Core Design Philosophy

> "If the player puts the phone down for five minutes, the world should still be entertaining."

Everything should support this philosophy.

Characters continue living.

Animals continue moving.

Water flows.

Lanterns flicker.

NPCs interact.

Clouds move.

Birds land.

The player should constantly notice small details.

---

# World Philosophy

The player is NOT the center of the universe.

The world exists with or without them.

Villagers have routines.

Buildings have purpose.

Animals behave naturally.

The world never feels frozen.

---

# Day & Night

There is NO automatic day/night cycle.

Instead...

The player taps the sky.

Tap the Sun → Day

Tap the Moon → Night

The transition should last roughly 10–15 seconds.

During the transition:

- lighting changes
- shadows move
- lanterns light one-by-one
- candles ignite
- birds disappear
- fireflies appear
- music changes
- NPC schedules change

No loading screens.

Everything happens naturally.

---

# Idle World Rule

When the player does nothing...

The world should still feel alive.

Examples:

Minute 1

- Birds land
- Pepita waters flowers
- Bakery chimney smokes

Minute 2

- Children run through village
- Butterflies move

Minute 3

- Wind blows
- Leaves fall
- Someone waves

Minute 4

- Couple sits on bench
- Dog chases butterfly

Minute 5

Rare random event

Examples:

- Parade
- Balloon escapes
- Shooting star
- Rainbow
- Festival begins

---

# Art Style

Bright.

Warm.

Inviting.

Whimsical.

Highly detailed.

Inspired by:

- Pixar
- Disney
- Coco
- Book illustrations

NOT realistic.

NOT pixel art.

NOT low-detail mobile graphics.

Every screenshot should feel like concept art.

---

# Asset Rules

ALL assets must be reusable.

Never paint entire scenes.

Everything should be modular.

Correct:

Background

+

Buildings

+

Props

+

Characters

+

Effects

Wrong:

One giant flattened background.

---

# Layer Order

Layer 8

UI

Layer 7

Foreground Objects

Trees

Signs

Branches

Layer 6

Characters

NPCs

Animals

Pepita

Layer 5

Props

Benches

Lanterns

Flower Pots

Tables

Layer 4

Buildings

Layer 3

Terrain Details

Flowers

Grass

Leaves

Layer 2

Ground

Stone

River

Paths

Layer 1

Sky

Mountains

Background

---

# Background Rules

Backgrounds contain ONLY:

- Sky
- Mountains
- Ground
- Rivers
- Terrain

NO

Characters

Buildings

Benches

Lanterns

Signs

Props

Trees

These are separate assets.

---

# Buildings

Every building is separate.

Every building has:

Day Version

Night Version

Night version only changes:

Lights

Windows

Lanterns

Glow

Building shape remains identical.

---

# Signs

Signs are NOT baked into buildings.

Example:

building_shop_small.png

+

florist_sign.png

or

bakery_sign.png

or

market_sign.png

One building should become many stores.

---

# Props

Everything decorative is separate.

Examples:

Bench

Lantern

Flower Pot

Barrel

Crate

Mailbox

Chair

Table

Watering Can

Flower Basket

Market Cart

These are reused everywhere.

---

# Effects

Effects are separate animated sprites.

Examples:

Lantern Flicker

Candle Flame

Butterfly

Firefly

Smoke

Leaves

Petals

Sparkles

River Flow

Water Splash

Clouds

---

# Characters

Characters are added LAST.

The world should already feel alive before characters exist.

---

# Production Roadmap

## Pack 001

Village Core

✔ Giant Tree

✔ Fountain

✔ Bridge

✔ Florist

✔ Bakery

✔ Temple

✔ Market

✔ Mariachi Stage

---

## Pack 002

Terrain

Stone Paths

River

Grass

Flower Beds

Cliffs

Water

---

## Pack 003

Nature

Trees

Bushes

Flowers

Rocks

Plants

---

## Pack 004

Village Props

Benches

Lanterns

Signs

Tables

Chairs

Crates

Barrels

Flower Pots

---

## Pack 005

Water Assets

River

Waterfall

Pond

Ripples

Fountain

---

## Pack 006

Lighting

Lanterns

Candles

Street Lamps

Window Lights

Fire Pits

---

## Pack 007

Effects

Smoke

Leaves

Butterflies

Fireflies

Petals

Dust

Sparkles

Rain

Snow

Fog

---

## Pack 008

Animals

Xolo

Cats

Birds

Owls

Fish

Butterflies

Bees

---

## Pack 009

Characters

Pepita

Villagers

Musicians

Children

Ghosts

---

# Hero Landmarks

Every map should contain one memorable landmark.

Examples

Spirit Village

- Giant Marigold Tree

Marigold Fields

- Stone Bridge

Parade Route

- Festival Archway

Family Neighborhood

- Courtyard Tree

Underworld Village

- Crystal River

Underworld Plaza

- Skull Fountain

Spirit Market

- Giant Market Canopy

Crystal Temple

- Crystal Waterfall

---

# Coding Rules

Codex should build systems that are reusable.

Never hardcode buildings.

Never hardcode NPC behavior.

Everything should be data-driven.

Buildings should load from JSON.

Characters should load from JSON.

Animations should load from JSON.

Future expansion should require adding assets, not rewriting code.

---

# Asset Standards

Transparent PNG

Consistent perspective

Consistent lighting

Consistent scale

Reusable

Game-ready

No baked shadows

No baked characters

No baked decorations

---

# Final Rule

Whenever adding anything to the game ask:

"Can this be reused somewhere else?"

If the answer is no...

Redesign it.

The goal is to build a reusable world-building library, not a collection of one-off artwork.



Day of the Dead/
│
├── README.md          ⭐ Project overview
├── docs/              ⭐ All design documents
│   ├── Vision.md
│   ├── Art Bible.md
│   ├── Asset Pipeline.md
│   └── Roadmap.md
│
├── assets/
│   ├── backgrounds/
│   ├── buildings/
│   ├── props/
│   ├── effects/
│   ├── nature/
│   └── characters/
│
└── references/
    ├── Inspiration/
    └── Templates/


DÍA DE LOS MUERTOS SPIRIT VILLAGE — MASTER ART STYLE TEMPLATE
Use the attached reference images as the EXACT visual style reference. Do not redesign the style.
Create assets for a cozy fantasy Día de los Muertos village game.
OVERALL ART STYLE
Premium mobile game quality
Hand-painted fantasy illustration style
Cozy adventure game feeling
Inspired by colorful Mexican folk art, papel picado, marigolds, and Día de los Muertos traditions
Similar feeling to a high-quality Nintendo-style cozy world
Rich, warm, magical atmosphere
Detailed but readable for a mobile game
COLOR PALETTE
Always use:
Deep royal purple
Indigo night blues
Warm orange candlelight
Bright marigold orange/yellow
Turquoise accents
Pink and magenta flowers
Warm stone textures
Emerald greens
Avoid:
Gray realistic environments
Dark horror style
Realistic photography
Muted colors
The world should feel:
magical, welcoming, colorful, alive
ENVIRONMENT DESIGN RULES
Buildings:
Colorful Mexican village architecture
Rounded adobe houses
Clay tile roofs
Painted doors
Flower-covered walls
Skull and flower decorations
Warm glowing windows
Papel picado banners
Ground:
Hand-laid cobblestone
Stone paths
Small cracks and imperfections
Flower petals scattered around
Marigold decorations
Nature:
Large beautiful trees
Flower gardens
Mountains in background
Rivers and fountains
Magical glowing plants
Lighting:
DAY:
Bright blue sky
Warm sunlight
Vibrant colors
NIGHT:
Deep blue/purple sky
Candle glow
Lantern lighting
Magical atmosphere
CHARACTER STYLE RULES
All characters must match the approved Pinto/Don Mateo/Xolo template.
Character design:
Cute chibi proportions
Large expressive eyes
Big head, small body
Rounded shapes
Full body visible
Mobile game character style
Never create:
Realistic humans
Anime style
Dark horror characters
Different art styles
SPRITE / ASSET RULES
For all usable game assets:
True transparent PNG background
No fake checkerboard
No white background
No text
No labels
No watermarks
For sprite sheets:
Same scale across every frame
Same camera distance
Same lighting
Same baseline
Clean spacing between sprites
Easy cropping
WORLD FEEL
The player should feel:
"I am exploring a magical Mexican village where spirits, flowers, memories, and family traditions come alive."
The world is:
Cozy
Emotional
Colorful
Magical
Family friendly
Full of discovery
Not:
Scary
Horror
Gloomy
Realistic
ART QUALITY CHECK BEFORE GENERATING
Before creating anything ask:
Does this look like it belongs beside the reference village?
Would Pepita, Xolo, Pinto, and Don Mateo naturally exist here?
Does it feel like one connected game world?
Would this look good as a premium mobile game screenshot?
If no → redo.
Asset naming examples:
Buildings:
spirit_village_house_flower_shop.png
Characters:
pepita_walk_down_01.png
Environment:
festival_plaza_day.png
Props:
marigold_candle_cluster.png
FINAL COMMAND:
"Use the attached reference images as the permanent style guide. Match the exact visual language, color palette, lighting, proportions, and magical Día de los Muertos atmosphere. Do not introduce a new style."
I would keep this as your first message whenever starting a new art session with me/Codex. It will prevent the "weird random style drift" that happened before.
