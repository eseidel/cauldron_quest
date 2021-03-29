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
Completed: 0:00:09.851873
Turns until blocked: {count: 10000, average: 37.0, min: 10, max: 79, median: 37.0, standardDeviation: 10.1}
Potion move rolled: {count: 10000, average: 12.3, min: 0, max: 28, median: 12.0, standardDeviation: 4.58}
Wizard move rolled: {count: 10000, average: 6.15, min: 0, max: 24, median: 6.0, standardDeviation: 3.18}
Magics rolled: {count: 10000, average: 12.3, min: 0, max: 39, median: 12.0, standardDeviation: 5.06}
Potions revealed: {count: 10000, average: 4.89, min: 0, max: 6, median: 5.0, standardDeviation: 1.2}
Potions swapped: {count: 10000, average: 0.0, min: 0, max: 0, median: 0.0, standardDeviation: 0.0}
Supercharms: {count: 10000, average: 1.88, min: 0, max: 19, median: 1.0, standardDeviation: 1.94}
Magics failed: {count: 10000, average: 5.52, min: 0, max: 21, median: 5.0, standardDeviation: 3.27}
Potion spaces moved: {count: 10000, average: 52.4, min: 0, max: 157, median: 52.0, standardDeviation: 21.6}
Wizard spaces moved: {count: 10000, average: 20.5, min: 0, max: 81, median: 19.0, standardDeviation: 10.7}
30.1% actual wins, N=10000
82.6% max wins, N=10000
