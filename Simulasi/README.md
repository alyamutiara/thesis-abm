## goals
Create a simple simulation of multi-room building that burns and evacuate people.

## note
1. Details of patches used in the simulation.
--------------------------------
| Name   | patch-id | color ID  | Desc
--------------------------------
| Walls        | -1       |		| not walkable
| Floor        | 0        |		| walkable
| Closed doors | -2       |             | not walkable but attract people to gather
| Doors        | 1        |		| can be passed
| Exits	       | 2        |		| goals
| Fire         | 1000     |		| need to be avoided
--------------------------------

2. Variable explanation.

3. 