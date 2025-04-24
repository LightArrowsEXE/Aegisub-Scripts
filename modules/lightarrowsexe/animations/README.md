# lightarrowsexe.animations

A collection of animation frames,
mainly aimed at
being a quick way
to get fancy drawings
for KFX.

## Example usage

Drawings are stored in arrays of strings.
You can iterate through them
using for example
the following code snippet:

```lua
-- TODO: Add example using 0x's util.fbf and karaOK's loop functions
```

## Drawings

Below is a list of drawing arrays.

Arrays can be called like this:

```lua
code once, anim = require 'lightarrowsexe.animations'
code once, starburst = anim.shapes.starburst.cartoon1
```

If no child is mentioned
in the tables below,
simply calling the parent itself
should return the array.

### Sparkles

Sparkle animations.

| Parent    | Child    | Length |
| --------- | -------- | ------ |
| starburst | cartoon1 | 4      |

### Animals

Various animal-related animations.

| Parent | Child | Length |
| ------ | ----- | ------ |
| cat    | burst | 4      |

### Pixelart

Various pixel art animations.

| Parent     | Child | Length |
| ---------- | ----- | ------ |
| sparkburst | -     | 8      |
| plasma     | -     | 9      |
