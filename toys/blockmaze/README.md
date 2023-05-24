Blockmaze
---

Blockmaze (originally titled *"game"*) was a prototype game done for one of my [dev.to](https://dev.to) articles. Gameplay was simply move all blocks to the goal by any means necessary. Mostly done via state machine logic.

There's a few primitive gameplay concepts here implemented:
* push blocks. can only push a block into an empty space, not another block (would exhibit slightly recursive logic otherwise)
* push blocks into goals, in order to progress to the next level
* tap buttons to lock and unlock doors
* collect keys to unlock certain doors permanently

This is the oldest game I developed here, and as such has a certain level of cruft. It is not rendered within WASM space.
