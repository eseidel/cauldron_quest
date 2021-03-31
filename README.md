# cauldron_quest

Just a quick script to look at winrates in my kid's favorite boardgame.

# How to run
% dart run --enable-asserts bin/simulate.dart

# Example output

`bin/charms.dart`
Charm % chance of success:
Reveal: 66.9%
Swap: 66.9%
Super Power: 37.6%

`bin/simulate.dart`
Simulating 10000 games...
Completed: 0:00:10.059390
Turns until blocked: {count: 10000, average: 32.4, min: 8, max: 72, median: 32.0, standardDeviation: 7.8}
Potion move rolled: {count: 10000, average: 10.8, min: 0, max: 31, median: 11.0, standardDeviation: 3.49}
Wizard move rolled: {count: 10000, average: 5.39, min: 0, max: 24, median: 5.0, standardDeviation: 2.83}
Magics rolled: {count: 10000, average: 10.8, min: 0, max: 35, median: 10.0, standardDeviation: 4.12}
Potions revealed: {count: 10000, average: 4.9, min: 0, max: 6, median: 5.0, standardDeviation: 1.18}
Potions swapped: {count: 10000, average: 0.169, min: 0, max: 4, median: 0.0, standardDeviation: 0.46}
Supercharms: {count: 10000, average: 1.22, min: 0, max: 13, median: 1.0, standardDeviation: 1.57}
Magics failed: {count: 10000, average: 4.53, min: 0, max: 20, median: 4.0, standardDeviation: 2.72}
Potion spaces moved: {count: 10000, average: 37.4, min: 0, max: 83, median: 38.0, standardDeviation: 11.5}
Potion spaces lost: {count: 10000, average: 6.0, min: 0, max: 71, median: 4.0, standardDeviation: 6.95}
Wizard spaces moved: {count: 10000, average: 17.9, min: 0, max: 78, median: 17.0, standardDeviation: 9.5}
50.6% actual wins, N=10000
79.2% max wins, N=10000

Issues:
* Unclear why median turn length dropped from 42 (expected?) to 32?