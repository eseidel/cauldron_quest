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
Completed: 0:00:09.015626
Turns until blocked: {count: 10000, average: 37.4, min: 9, max: 78, median: 37.0, standardDeviation: 10.1}
Potion move rolled: {count: 10000, average: 12.5, min: 0, max: 34, median: 12.0, standardDeviation: 4.63}
Wizard move rolled: {count: 10000, average: 6.27, min: 0, max: 23, median: 6.0, standardDeviation: 3.2}
Magics rolled: {count: 10000, average: 12.5, min: 0, max: 35, median: 12.0, standardDeviation: 5.03}
Potions revealed: {count: 10000, average: 5.48, min: 0, max: 6, median: 6.0, standardDeviation: 1.12}
Potions swapped: {count: 10000, average: 0.0, min: 0, max: 0, median: 0.0, standardDeviation: 0.0}
Supercharms: {count: 10000, average: 1.64, min: 0, max: 11, median: 1.0, standardDeviation: 1.9}
Magics failed: {count: 10000, average: 5.36, min: 0, max: 22, median: 5.0, standardDeviation: 3.23}
Potion spaces moved: {count: 10000, average: 51.3, min: 0, max: 139, median: 50.0, standardDeviation: 21.8}
Wizard spaces moved: {count: 10000, average: 20.9, min: 0, max: 79, median: 20.0, standardDeviation: 10.8}
29.2% actual wins, N=10000
81.6% max wins, N=10000
