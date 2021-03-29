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
Completed: 0:00:09.564916
Turns until blocked: {count: 10000, average: 37.1, min: 8, max: 79, median: 37.0, standardDeviation: 10.2}
Potion move rolled: {count: 10000, average: 12.4, min: 0, max: 33, median: 12.0, standardDeviation: 4.65}
Wizard move rolled: {count: 10000, average: 6.2, min: 0, max: 24, median: 6.0, standardDeviation: 3.18}
Magics rolled: {count: 10000, average: 12.4, min: 0, max: 34, median: 12.0, standardDeviation: 5.11}
Potions revealed: {count: 10000, average: 4.9, min: 0, max: 6, median: 5.0, standardDeviation: 1.19}
Potions swapped: {count: 10000, average: 0.182, min: 0, max: 4, median: 0.0, standardDeviation: 0.468}
Supercharms: {count: 10000, average: 1.84, min: 0, max: 13, median: 1.0, standardDeviation: 1.93}
Magics failed: {count: 10000, average: 5.49, min: 0, max: 25, median: 5.0, standardDeviation: 3.3}
Potion spaces moved: {count: 10000, average: 52.3, min: 0, max: 136, median: 52.0, standardDeviation: 22.0}
Wizard spaces moved: {count: 10000, average: 20.7, min: 0, max: 78, median: 19.0, standardDeviation: 10.7}
30.6% actual wins, N=10000
81.3% max wins, N=10000
