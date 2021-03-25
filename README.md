# cauldron_quest

Just a quick script to look at winrates in my kid's favorite boardgame.

# How to run
% dart run --enable-asserts lib/rules.dart

# Example output

Charm % chance of success:
Reveal: 66.9%
Swap: 67.0%
Super Power: 37.8%

Simulating 10000 games:
Turns until blocked: {count: 10000, average: 41.9, min: 9, max: 122, median: 40.0, standardDeviation: 14.7}
Magics rolled: {count: 10000, average: 13.9, min: 0, max: 49, median: 13.0, standardDeviation: 6.53}
Potions revealed: {count: 10000, average: 9.34, min: 0, max: 37, median: 9.0, standardDeviation: 4.74}
Potion move rolled: {count: 10000, average: 14.0, min: 0, max: 53, median: 13.0, standardDeviation: 6.58}
Wizard move rolled: {count: 10000, average: 6.95, min: 0, max: 32, median: 6.0, standardDeviation: 3.73}
Potion spaces moved: {count: 10000, average: 46.6, min: 0, max: 171, median: 44.0, standardDeviation: 22.0}
Wizard spaces moved: {count: 10000, average: 23.2, min: 0, max: 109, median: 21.0, standardDeviation: 12.5}
72.4% max wins, N=10000


Issues:
* Need a better representation of the move graph.
* 