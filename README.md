# <center>Linchpin Perk Deck</center>

> *The Linchpin is the quiet constant that holds a crew together when everything starts to fall apart. Not a boss nor a bruiser, the Linchpin thrives in the thick of the action, reading the room and reinforcing the people around them. When a job goes sideways, the Linchpin is the one keeping everyone sharp, steady, and alive. Stick close to them, and the crew becomes more than the sum of its parts.*

The Linchpin perk deck is a support-oriented perk deck that focuses on all the ways to support the crew that other support perk decks don't or barely do.

The perk deck was *very much* inspired by a Biker rework idea posted by `@kasane_teto_pd2` in the Restoration Mod Discord, though with some of my own spins on it. I wanted to practice both working with Lua and PD2 modding, and something semi-complicated like this looked to be the perfect way to do so.

I had a few design goals in mind for this perk deck:
- The perk deck should encourage proximity to one another, without overly punishing detaching from the crew for a bit.
- A Linchpin user should not feel like they're nerfed overmuch just to support the team.
- The perk deck should not overly replicate other support perk decks. This means primarily a limited amount of healing and no-or-barely-any resistances.
- 1 Linchpin user should be good, but 2 should be optimal. However, having 2 Linchpin users should give up just enough that only the best players should comfortably be able to run it.
- The perk deck should give boosts to rarely-boosted features.

## Prerequisites

This perk deck is **only available for the Restoration Mod**, both mainly because I can't be arsed to keep a Vanilla-compatible version, and also because I primarily play ResMod nowadays.

## Installation

1. *(Get Restoration Mod.)*
2. Navigate to the Releases page (should be on the right).
3. Download the zip file for the latest release.

## Expected Mod Collisions

I tried leaning on hooks as much as possible, so I expect that this perk deck should be have with any other mods that do so as well (as far as I understand PD2 modding). I *have* forcibly overwritten the `PlayerDamage._update_regenerate_timer()` function, so any mod that attempts to do the same might cause collisions.

## Deck Details

### Cohesion Stacks, and Gaining and Losing Them

The deck is primarily oriented around gaining Cohesion stacks and keeping them as high as possible. Cohesion stacks are also dvided into two important number: their actual **amount** and their **tendency**.

The **amount** is the simpler of these two. The amount of Cohesion stacks is quite literally the amount you actually have. The **tendency** determines (in part) how it changes. Your Cohesion stack amount will *tend towards* the tendency. This means that if your amount is below your tendency, your amount will slowly increase, and if it's above it, it'll decrease.

For Linchpin perk deck users, your tendency is easy to set: **your tendency will equal to 8 times the amount of crew members within 18 metres of you**. You also count here, so you will always have at least 8 tendency. Having another ally within 18 metres increases this to 16, a third to 24, and a fourth to 32.

For non-Linchpin perk deck users, **you gain the tendency of any Linchpin user if you are within 18 metres of them**. This means that you will typically default to 0, but getting near a Linchpin perk deck user will set it to 16 or more.

Additionally, the farther away your tendency is from your current amount, the faster your amount will tend to it. So even if you have 0 Cohesion stacks, it's worth joining the Linchpin perk deck user with all the others, as your tendency will immediately be set to 32, and your amount will start shooting up.

As a counterbalance, for every **16 damage** you take, you lose a stack of Cohesion. **Health is counted doubly** for this, so for example, if you lose 4 armour and 6 health, you lose 1 stack of Cohesion (because 4 + 6 \* 2 = 4 + 12 = 16).

### Using Cohesion Stacks

Cohesion stacks grant passive benefits based on the perk cards the Linchpin user has chosen. Every unique card in the perk deck allows for a choice between two cards, with the last one offering 4. **Multiple Linchpin users choosing the same card choice will not stack its effects** unless it explicitly says so -- but multiple Linchpin users on the same crew are encouraged to "double-dip" by picking *both* choices (or two different choices, in the last card's case).

Cohesion stacks are not treated differently just because they were received due to different Linchpin users. Each crew member simply just has Cohesion stacks as long as there is at least one Linchpin user on the crew, and Linchpin users affect these.

As an example, for the first Card "Tight Formation", if one Linchpin user picks the "Stick Together!" choice, while the other "Eyes Open!", **both effects will activate** when a crew member gains enough Cohesion stacks.