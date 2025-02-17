# Cloth of Gold (processing)

This is a barebones implementation of Cloth of Gold for developing the base algorithms.
Cloth of Gold is a PvP strategy game which uses a modified Conway's Game of Life.

## Gameplay

The game begins with each player taking turns placing their initial population (up to 10 units) into the world.
Each round consists of three phases:

1. Players take turns placing units in the world (up to 10 units each)
2. The world is updated based on the rules described below for 168 generations (7 24-hour days)
3. The scores of each player are updated based on both unit count and territory control

The game ends when the win condition of one of the players is met or when the mutual loss condition is met.

### Placement Rules

Each player will take turns placing units in the world.

- Players may place up to 10 units per turn
- Players must place at least 1 unit per turn
- Players may place units with the following restrictions:
  - Players may not place a unit within a 1-cell radius of another player's unit
  - Players may not place a unit on top of another unit
  - Players may not place a unit on top of a dead unit
  - Players may not place units outside their territory (except for their first unit)
  - Players may not place units in overlapping territory zones
- Players may delete units from the world only if they have been placed during their current turn
- Territory is determined by metaball fields around existing units:
  - Each player's units create a field of influence
  - Areas where field strength > 1.0 are considered that player's territory
  - Areas where both players' fields are > 1.0 are considered contested territory

## Game Logic

Let there be generic player populations $A$ and $B$ and let there be a neutral non-player population $C$.
Let the world be denoted $\mathbf{W}$ such that $\mathbf{W} \in U^{m \times n}$ where $U = \{0, a, b, c, d\}$ such that:

- 0 represents an empty cell
- $a$ represents a cell belonging to A
- $b$ represents a cell belonging to B
- $c$ represents a cell belonging to C
- $d$ represents a cell that has been killed

Let $\mathbf{W}(t)$ represent the world at time $t$ and $w_{i,j}(t)$ represent the value of the cell at position $(i,j)$ at time $t$ in the world such that $w_{i,j}(t) \in U$.
Define the neighbor counting functions:

$$
N_A[w_{i,j}(t)] = \sum_{k=i-1}^{i+1} \sum_{l=j-1}^{j+1} [w_{k,l}(t) = a] : (k,l) \ne (i,j)
$$

$$
N_B[w_{i,j}(t)] = \sum_{k=i-1}^{i+1} \sum_{l=j-1}^{j+1} [w_{k,l}(t) = b] : (k,l) \ne (i,j)
$$

$$
N_C[w_{i,j}(t)] = \sum_{k=i-1}^{i+1} \sum_{l=j-1}^{j+1} [w_{k,l}(t) = c] : (k,l) \ne (i,j)
$$

$$
N[w_{i,j}(t)] = N_A[w_{i,j}(t)] + N_B[w_{i,j}(t)] + N_C[w_{i,j}(t)]
$$

The value of each cell is updated at each time step $t$ according to the following rules:

$$
w_{i,j}(t+1) = 0 : w_{i,j}(t) \in U \\ \land \ (N[w_{i,j}(t)] < 2 \lor N[w_{i,j}(t)] > 3) \\ \land \\ N_A[w_{i,j}(t)] = N_B[w_{i,j}(t)]
$$

$$
w_{i,j}(t+1) = a : w_{i,j}(t) \in \{0, a, c\} \\ \land \ ((w_{i,j}(t) \ne 0 \land 2 \le N[w_{i,j}(t)] \le 3) \\ \lor \ (w_{i,j}(t) = 0 \land N[w_{i,j}(t)] = 3)) \\ \land \ N_A[w_{i,j}(t)] > N_B[w_{i,j}(t)]
$$

$$
w_{i,j}(t+1) = b : w_{i,j}(t) \in \{0, b, c\} \\ \land \ ((w_{i,j}(t) \ne 0 \land 2 \le N[w_{i,j}(t)] \le 3) \\ \lor \ (w_{i,j}(t) = 0 \land N[w_{i,j}(t)] = 3)) \\ \land \ N_A[w_{i,j}(t)] < N_B[w_{i,j}(t)]
$$

$$
w_{i,j}(t+1) = w_{i,j}(t) : w_{i,j}(t) \in \{0, a, b, c\} \\ \land \ ((w_{i,j}(t) \ne 0 \land 2 \le N[w_{i,j}(t)] \le 3) \\ \lor \ (w_{i,j}(t) = 0 \land N[w_{i,j}(t)] = 3)) \\ \land \ N_A[w_{i,j}(t)] = N_B[w_{i,j}(t)]
$$

$$
w_{i,j}(t+1) = d : w_{i,j}(t) \in \{a, b\} \\ \land \ 2 \le N[w_{i,j}(t)] \le 3 \\ \land \ N_A[w_{i,j}(t)] \ne N_B[w_{i,j}(t)]
$$

The outcomes of a cell are as follows:

- Cell dies of loneliness or stays empty (rule 1)
- Cell dies of overpopulation or stays empty (rule 2)
- Cell becomes or remains A (rule 3)
- Cell becomes or remains B (rule 4)
- Cell stays in current state (rule 5)
- Cell dies if it belongs to a player and opposing force is stronger (rule 6)

Let $A(t)$ represent the number of A cells at time $t$ such that:

$$
A(t) = \sum_{i=1}^{m} \sum_{j=1}^{n} [w_{i,j}(t) = a]
$$

Let $B(t)$ represent the number of B cells at time $t$ such that:

$$
B(t) = \sum_{i=1}^{m} \sum_{j=1}^{n} [w_{i,j}(t) = b]
$$

Let $\mathcal{S}_A(t)$ represent the score of A at time $t$ such that:

$$
\mathcal{S}_A(t) = A(t) - B(t)
$$

Let $\mathcal{S}_B(t)$ represent the score of B at time $t$ such that:

$$
\mathcal{S}_B(t) = B(t) - A(t)
$$

Let the win condition of player $A$ be defined as:

$$
\mathcal{S}_B(t) \le \mathcal{S}_B(t+1) \le 0
$$

Let the win condition of player $B$ be defined as:

$$
\mathcal{S}_A(t) \le \mathcal{S}_A(t+1) \le 0
$$

Let the mutual loss condition be defined as:

$$
\mathcal{S}_A(t) \le 0 \ \land \ \mathcal{S}_B(t) \le 0
$$

## Scoring

The game tracks several metrics for each player:

- Unit Count: The total number of living units on the board
- Territory Size: The number of cells within a player's territory
- Score: Calculated as (player's units - opponent's units)

## Future Directions

- Still life pattern counting
  - Specific still life patterns and combinations of still life patterns give perks like extra units per placement phase, buffs, spells, etc.
- Natural systems
  - Fires, floods, lightning, etc.
- Dynamical systems to model terrain and weather
  - Terrain type modulates effect of still life pattern perks
  - Weather affects terrain change, fire spread, etc.
- Boarder drawing around player unit clusters
  - Player unit clusters are defined by the convex hull of the player's units plus a buffer zone
  - Placement of units inside the buffer zone is allowed by the player
  - Placement of units outside of the buffer zone is forbidden by the player
- More complex unit types
  - Aggressive non-player units
  - Defensive non-player units
  - Neutral wildlife
    - Follows noise patterns
    - Flees from player units
  - Aggressive wildlife
    - Follows noise patterns
    - Pursues and attacks player units
  - Defensive wildlife
    - Follows noise patterns
    - Attacks player if player unit enters range
