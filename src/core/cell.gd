class_name Cell
extends RefCounted
## Semantic values a [Grid] cell can hold.
##
## Kept deliberately tiny and dependency-free so every layer can agree on what
## a "wall" or "floor" is without coupling to generation, analysis, or view.

const FLOOR := 0
const WALL := 1
