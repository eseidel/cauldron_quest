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
Completed: 0:00:08.635620
Turns until blocked: {count: 10000, average: 33.2, min: 10, max: 76, median: 33.0, standardDeviation: 8.51}
Potion move rolled: {count: 10000, average: 11.1, min: 0, max: 31, median: 11.0, standardDeviation: 3.69}
Wizard move rolled: {count: 10000, average: 5.57, min: 0, max: 22, median: 5.0, standardDeviation: 2.94}
Magics rolled: {count: 10000, average: 11.1, min: 0, max: 35, median: 11.0, standardDeviation: 4.45}
Potions revealed: {count: 10000, average: 4.83, min: 0, max: 6, median: 5.0, standardDeviation: 1.2}
Potions swapped: {count: 10000, average: 0.17, min: 0, max: 5, median: 0.0, standardDeviation: 0.459}
Supercharms: {count: 10000, average: 1.36, min: 0, max: 11, median: 1.0, standardDeviation: 1.7}
Magics failed: {count: 10000, average: 4.7, min: 0, max: 23, median: 4.0, standardDeviation: 2.87}
Potion spaces moved: {count: 10000, average: 45.1, min: 0, max: 133, median: 44.0, standardDeviation: 17.3}
Wizard spaces moved: {count: 10000, average: 18.5, min: 0, max: 74, median: 17.0, standardDeviation: 9.86}
47.6% actual wins, N=10000
81.8% max wins, N=10000
