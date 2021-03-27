# cauldron_quest

Just a quick script to look at winrates in my kid's favorite boardgame.

# How to run
% dart run --enable-asserts bin/simulate.dart

# Example output

Charm % chance of success:
Reveal: 66.9%
Swap: 66.9%
Super Power: 37.6%

Simulating 10000 games:
Turns until blocked: {count: 10000, average: 41.9, min: 9, max: 120, median: 40.0, standardDeviation: 14.6}
Potion move rolled: {count: 10000, average: 14.0, min: 0, max: 46, median: 13.0, standardDeviation: 6.52}
Wizard move rolled: {count: 10000, average: 6.96, min: 0, max: 29, median: 6.0, standardDeviation: 3.73}
Magics rolled: {count: 10000, average: 13.9, min: 0, max: 48, median: 13.0, standardDeviation: 6.48}
Potions revealed: {count: 10000, average: 5.51, min: 0, max: 6, median: 6.0, standardDeviation: 1.1}
Potion spaces moved: {count: 10000, average: 59.7, min: 0, max: 259, median: 54.0, standardDeviation: 32.6}
Wizard spaces moved: {count: 10000, average: 23.2, min: 0, max: 97, median: 21.0, standardDeviation: 12.5}
78.6% max wins, N=10000


Issues:
* Need a better representation of the move graph.
* 