# cauldron_quest

Just a quick script to look at winrates in my kid's favorite boardgame.

# How to run
% dart run --enable-asserts lib/rules.dart

# Example output

Turns until blocked: {count: 10000, average: 42.1, min: 8, max: 116, median: 40.0, standardDeviation: 14.5}
Magics rolled: {count: 10000, average: 14.0, min: 0, max: 52, median: 13.0, standardDeviation: 6.51}
Potions revealed: {count: 10000, average: 4.61, min: 0, max: 19, median: 4.0, standardDeviation: 2.78}
Potion move rolled: {count: 10000, average: 14.0, min: 0, max: 47, median: 13.0, standardDeviation: 6.5}
Wizard move rolled: {count: 10000, average: 7.04, min: 0, max: 27, median: 7.0, standardDeviation: 3.73}
Potion spaces moved: {count: 10000, average: 46.7, min: 0, max: 152, median: 44.0, standardDeviation: 21.7}
Wizard spaces moved: {count: 10000, average: 23.5, min: 0, max: 89, median: 22.0, standardDeviation: 12.5}
5272 max possible wins
