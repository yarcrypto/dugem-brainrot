# Dugem Brainrot

[![Dugem Brainrot on make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Rank](https://make.fun/badge/roblox-brainrot-01/yarcrypto/dugem-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Reward](https://make.fun/badge/roblox-brainrot-01/yarcrypto/dugem-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A Steal-a-Brainrot style collection game set in a 3D nightclub — a dugem
(Indonesian club party) world of checkered dance floors, a DJ stage, a disco
ball and eight VIP booths. Absurd dugem-flavoured brainrots ride a glowing
conveyor across the dance floor, you buy them, they earn cash every second
from your booth, and rivals try to steal them while the Satpam sweeps the
floor on his Razia.

**Play it:** https://www.roblox.com/games/127377706029368

## How to play

1. **Buy brainrots** — walk up to a brainrot on the conveyor and press **E**.
   Each one shows its name, rarity and $/sec on its label.
2. **Earn** — a bought brainrot walks to your VIP booth and pays you every
   second. Save up for rarer ones: Common, Rare, Epic, Legendary, Mythic,
   Brainrot God.
3. **Mutations** — brainrots can spawn Neon (x2), Gold (x5), Rainbow (x10)
   or Disco (x25), multiplying what they earn.
4. **Steal** — press **E** on a brainrot in someone else's booth to carry it
   home to your booth. If you make it, it is yours.
5. **Defend** — press **Tampar** to slap a thief (it drops YOUR brainrot if
   they stole it) and **Kunci Booth** to lock your booth for 30 seconds.
6. **Razia Satpam** — every 90 seconds a security sweep crosses the floor.
   If you are caught outside your booth carrying a stolen brainrot, you
   drop it.
7. **Progress** — spend cash on upgrades (booth slots, run speed, slap
   power) and **Rebirth** to reset your cash for a permanent x2 income
   multiplier.

## The cast

DJ Meong Koplo, Bocil Subwoofer, Mbak Lampu Disko, Pak Satpam Rave, Kuda
Karaoke, Nenek Breakbeat, Tante Dangdut Laser, Om Bass Beton, Ratu
Glowstick, Sultan Strobe, Dewa Dugem and Raja Koplo Abadi — all original
characters made for this game.

## Build

Rojo project (`default.project.json`), built with
`rojo build default.project.json --output game.rbxl`. Server logic lives in
`src/server`, shared brainrot definitions in `src/shared`, and the HUD in
`src/client`. `main.ts` hands the game in to make.fun. Screenshots in
`screenshots/` are composed renders of the game's own world, characters and
HUD (no Roblox Studio is available in this build environment); the first one
is the game's thumbnail.
