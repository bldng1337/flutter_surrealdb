- date: 2026-10-08T00:42:26.927496
- os: "Windows 10 Home" 10.0 (Build 26200)
- samples per benchmark: 30 (+3 untimed warmup)
- sizes: [100, 1000, 10000], backends: [mem, surrealkv, rocksdb]
- engine: 3.3.0

| backend | size | table | benchmark | ops/sample | min | p50 | p99 | max | mean | ops/s |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| dart | - | - | encode_single | 1 | 7 µs | 7 µs | 33 µs | 33 µs | 9 µs | 111.1k |
| dart | - | - | convert_1k | 1000 | 7.68 ms | 10.20 ms | 15.89 ms | 16.30 ms | 10.79 ms | 92.7k |
| dart | - | - | encode_100 | 100 | 2.06 ms | 2.83 ms | 3.69 ms | 3.74 ms | 2.82 ms | 35.5k |
| dart | - | - | encode_1k | 1000 | 21.35 ms | 26.78 ms | 48.28 ms | 49.54 ms | 30.07 ms | 33.3k |
| dart | - | - | encode_10k | 10000 | 188.90 ms | 239.34 ms | 336.66 ms | 337.27 ms | 250.10 ms | 40.0k |
| dart | - | - | decode_single | 1 | 35 µs | 39 µs | 173 µs | 214 µs | 46 µs | 21.7k |
| dart | - | - | cbor_decode_1k | 1000 | 17.21 ms | 23.28 ms | 31.34 ms | 31.70 ms | 23.32 ms | 42.9k |
| dart | - | - | decode_100 | 100 | 2.10 ms | 2.52 ms | 3.69 ms | 3.79 ms | 2.58 ms | 38.8k |
| dart | - | - | decode_1k | 1000 | 28.28 ms | 35.58 ms | 45.37 ms | 46.60 ms | 35.61 ms | 28.1k |
| dart | - | - | decode_10k | 10000 | 328.84 ms | 417.90 ms | 511.79 ms | 517.25 ms | 422.66 ms | 23.7k |
| dart | - | - | roundtrip_1k | 1000 | 45.73 ms | 63.64 ms | 98.33 ms | 102.86 ms | 65.91 ms | 15.2k |
| mem | 100 | bench_plain | insert_batch | 100 | 8.91 ms | 11.25 ms | 16.79 ms | 16.84 ms | 11.83 ms | 8.5k |
| mem | 100 | bench_plain | create_single_x100 | 100 | 32.18 ms | 38.56 ms | 78.66 ms | 80.17 ms | 41.21 ms | 2.4k |
| mem | 100 | bench_plain | delete_all | 100 | 5.88 ms | 7.67 ms | 17.09 ms | 17.20 ms | 9.15 ms | 10.9k |
| mem | 100 | bench_plain | select_all | 1 | 3.87 ms | 4.53 ms | 6.36 ms | 6.61 ms | 4.67 ms | 214.1 |
| mem | 100 | bench_plain | count_aggregate | 1 | 198 µs | 289 µs | 490 µs | 510 µs | 302 µs | 3.3k |
| mem | 100 | bench_plain | point_read_x100 | 100 | 19.73 ms | 29.69 ms | 58.46 ms | 58.87 ms | 33.94 ms | 2.9k |
| mem | 100 | bench_plain | merge_point_x100 | 100 | 23.04 ms | 33.91 ms | 47.35 ms | 47.53 ms | 34.70 ms | 2.9k |
| mem | 100 | bench_plain | update_bulk | 1 | 7.59 ms | 11.18 ms | 17.06 ms | 17.15 ms | 11.76 ms | 85.0 |
| mem | 100 | bench_plain | filter_eq | 1 | 790 µs | 971 µs | 1.48 ms | 1.53 ms | 1.03 ms | 974.7 |
| mem | 100 | bench_plain | filter_range | 1 | 1.32 ms | 1.50 ms | 3.12 ms | 3.45 ms | 1.60 ms | 624.2 |
| mem | 100 | bench_plain | filter_compound | 1 | 564 µs | 678 µs | 939 µs | 941 µs | 714 µs | 1.4k |
| mem | 100 | bench_idx | insert_batch | 100 | 16.59 ms | 20.65 ms | 34.89 ms | 35.68 ms | 22.66 ms | 4.4k |
| mem | 100 | bench_idx | create_single_x100 | 100 | 41.41 ms | 53.01 ms | 88.26 ms | 88.89 ms | 56.07 ms | 1.8k |
| mem | 100 | bench_idx | delete_all | 100 | 11.21 ms | 13.61 ms | 25.24 ms | 26.73 ms | 14.59 ms | 6.9k |
| mem | 100 | bench_idx | select_all | 1 | 4.00 ms | 4.37 ms | 6.31 ms | 6.42 ms | 4.60 ms | 217.4 |
| mem | 100 | bench_idx | count_aggregate | 1 | 238 µs | 355 µs | 778 µs | 805 µs | 386 µs | 2.6k |
| mem | 100 | bench_idx | point_read_x100 | 100 | 22.52 ms | 26.25 ms | 37.94 ms | 38.22 ms | 27.43 ms | 3.6k |
| mem | 100 | bench_idx | merge_point_x100 | 100 | 25.01 ms | 33.18 ms | 60.93 ms | 61.96 ms | 36.72 ms | 2.7k |
| mem | 100 | bench_idx | update_bulk | 1 | 6.56 ms | 8.40 ms | 16.88 ms | 17.00 ms | 9.63 ms | 103.8 |
| mem | 100 | bench_idx | filter_eq | 1 | 628 µs | 860 µs | 1.53 ms | 1.56 ms | 939 µs | 1.1k |
| mem | 100 | bench_idx | filter_range | 1 | 1.25 ms | 1.70 ms | 2.70 ms | 2.74 ms | 1.76 ms | 568.8 |
| mem | 100 | bench_idx | filter_compound | 1 | 856 µs | 1.16 ms | 1.75 ms | 1.81 ms | 1.20 ms | 831.9 |
| mem | 1000 | bench_plain | insert_batch | 1000 | 126.76 ms | 150.12 ms | 221.63 ms | 221.88 ms | 158.96 ms | 6.3k |
| mem | 1000 | bench_plain | create_single_x100 | 100 | 31.13 ms | 39.53 ms | 66.25 ms | 66.40 ms | 42.80 ms | 2.3k |
| mem | 1000 | bench_plain | delete_all | 1000 | 65.03 ms | 75.78 ms | 138.35 ms | 142.67 ms | 85.93 ms | 11.6k |
| mem | 1000 | bench_plain | select_all | 1 | 44.22 ms | 54.84 ms | 81.11 ms | 81.17 ms | 56.62 ms | 17.7 |
| mem | 1000 | bench_plain | count_aggregate | 1 | 551 µs | 746 µs | 957 µs | 967 µs | 732 µs | 1.4k |
| mem | 1000 | bench_plain | point_read_x100 | 100 | 21.11 ms | 30.82 ms | 49.78 ms | 50.27 ms | 32.77 ms | 3.1k |
| mem | 1000 | bench_plain | merge_point_x100 | 100 | 22.38 ms | 36.45 ms | 55.59 ms | 55.91 ms | 38.56 ms | 2.6k |
| mem | 1000 | bench_plain | update_bulk | 1 | 68.05 ms | 83.38 ms | 107.69 ms | 108.05 ms | 85.75 ms | 11.7 |
| mem | 1000 | bench_plain | filter_eq | 1 | 5.27 ms | 6.01 ms | 10.06 ms | 11.10 ms | 6.31 ms | 158.6 |
| mem | 1000 | bench_plain | filter_range | 1 | 9.63 ms | 11.52 ms | 20.44 ms | 20.88 ms | 11.94 ms | 83.8 |
| mem | 1000 | bench_plain | filter_compound | 1 | 4.93 ms | 7.22 ms | 8.86 ms | 8.93 ms | 7.20 ms | 138.9 |
| mem | 1000 | bench_idx | insert_batch | 1000 | 392.85 ms | 514.51 ms | 578.50 ms | 578.84 ms | 508.29 ms | 2.0k |
| mem | 1000 | bench_idx | create_single_x100 | 100 | 38.86 ms | 52.91 ms | 86.17 ms | 89.60 ms | 56.52 ms | 1.8k |
| mem | 1000 | bench_idx | delete_all | 1000 | 116.84 ms | 152.16 ms | 241.16 ms | 243.87 ms | 163.29 ms | 6.1k |
| mem | 1000 | bench_idx | select_all | 1 | 37.99 ms | 49.23 ms | 74.97 ms | 76.66 ms | 51.16 ms | 19.5 |
| mem | 1000 | bench_idx | count_aggregate | 1 | 353 µs | 460 µs | 923 µs | 924 µs | 488 µs | 2.0k |
| mem | 1000 | bench_idx | point_read_x100 | 100 | 24.04 ms | 30.95 ms | 62.17 ms | 64.61 ms | 36.93 ms | 2.7k |
| mem | 1000 | bench_idx | merge_point_x100 | 100 | 31.31 ms | 40.24 ms | 64.68 ms | 64.97 ms | 43.26 ms | 2.3k |
| mem | 1000 | bench_idx | update_bulk | 1 | 68.06 ms | 82.44 ms | 132.51 ms | 133.50 ms | 87.59 ms | 11.4 |
| mem | 1000 | bench_idx | filter_eq | 1 | 4.12 ms | 4.67 ms | 6.58 ms | 7.20 ms | 4.73 ms | 211.5 |
| mem | 1000 | bench_idx | filter_range | 1 | 9.17 ms | 10.21 ms | 11.78 ms | 11.78 ms | 10.19 ms | 98.2 |
| mem | 1000 | bench_idx | filter_compound | 1 | 5.20 ms | 5.98 ms | 6.83 ms | 6.86 ms | 6.05 ms | 165.3 |
| mem | 10000 | bench_plain | insert_batch | 10000 | 3.903 s | 5.457 s | 5.852 s | 5.883 s | 5.309 s | 1.9k |
| mem | 10000 | bench_plain | create_single_x100 | 100 | 38.87 ms | 51.15 ms | 79.65 ms | 80.39 ms | 53.25 ms | 1.9k |
| mem | 10000 | bench_plain | delete_all | 10000 | 860.20 ms | 1.153 s | 1.535 s | 1.617 s | 1.148 s | 8.7k |
| mem | 10000 | bench_plain | select_all | 1 | 338.95 ms | 379.24 ms | 452.29 ms | 462.23 ms | 386.88 ms | 2.6 |
| mem | 10000 | bench_plain | count_aggregate | 1 | 894 µs | 1.18 ms | 2.38 ms | 2.56 ms | 1.32 ms | 755.3 |
| mem | 10000 | bench_plain | point_read_x100 | 100 | 29.80 ms | 33.81 ms | 41.35 ms | 41.86 ms | 34.77 ms | 2.9k |
| mem | 10000 | bench_plain | merge_point_x100 | 100 | 33.48 ms | 41.56 ms | 50.73 ms | 50.95 ms | 42.00 ms | 2.4k |
| mem | 10000 | bench_plain | update_bulk | 1 | 493.58 ms | 580.67 ms | 699.75 ms | 707.01 ms | 583.15 ms | 1.7 |
| mem | 10000 | bench_plain | filter_eq | 1 | 31.52 ms | 37.10 ms | 51.70 ms | 54.77 ms | 37.82 ms | 26.4 |
| mem | 10000 | bench_plain | filter_range | 1 | 67.01 ms | 74.12 ms | 97.73 ms | 98.43 ms | 76.79 ms | 13.0 |
| mem | 10000 | bench_plain | filter_compound | 1 | 22.03 ms | 25.94 ms | 31.84 ms | 31.86 ms | 26.10 ms | 38.3 |
| mem | 10000 | bench_idx | insert_batch | 10000 | 33.420 s | 62.131 s | 74.301 s | 75.115 s | 58.570 s | 170.7 |
| mem | 10000 | bench_idx | create_single_x100 | 100 | 70.45 ms | 98.34 ms | 121.38 ms | 121.45 ms | 96.79 ms | 1.0k |
| mem | 10000 | bench_idx | delete_all | 10000 | 1.165 s | 2.246 s | 3.199 s | 3.294 s | 2.073 s | 4.8k |
| mem | 10000 | bench_idx | select_all | 1 | 590.64 ms | 718.37 ms | 846.61 ms | 856.42 ms | 715.75 ms | 1.4 |
| mem | 10000 | bench_idx | count_aggregate | 1 | 1.31 ms | 1.96 ms | 2.80 ms | 2.96 ms | 1.98 ms | 505.6 |
| mem | 10000 | bench_idx | point_read_x100 | 100 | 42.77 ms | 54.42 ms | 74.12 ms | 76.17 ms | 56.19 ms | 1.8k |
| mem | 10000 | bench_idx | merge_point_x100 | 100 | 66.81 ms | 91.59 ms | 118.57 ms | 120.59 ms | 91.62 ms | 1.1k |
| mem | 10000 | bench_idx | update_bulk | 1 | 983.62 ms | 1.290 s | 1.677 s | 1.703 s | 1.305 s | 0.8 |
| mem | 10000 | bench_idx | filter_eq | 1 | 72.77 ms | 89.31 ms | 123.44 ms | 126.80 ms | 92.79 ms | 10.8 |
| mem | 10000 | bench_idx | filter_range | 1 | 123.32 ms | 157.04 ms | 210.69 ms | 211.66 ms | 164.24 ms | 6.1 |
| mem | 10000 | bench_idx | filter_compound | 1 | 40.56 ms | 53.85 ms | 68.66 ms | 69.77 ms | 53.43 ms | 18.7 |
| surrealkv | 100 | bench_plain | insert_batch | 100 | 11.86 ms | 20.08 ms | 30.76 ms | 30.89 ms | 20.89 ms | 4.8k |
| surrealkv | 100 | bench_plain | create_single_x100 | 100 | 240.90 ms | 272.45 ms | 290.59 ms | 292.14 ms | 270.16 ms | 370.2 |
| surrealkv | 100 | bench_plain | delete_all | 100 | 13.12 ms | 23.07 ms | 31.26 ms | 31.63 ms | 22.86 ms | 4.4k |
| surrealkv | 100 | bench_plain | select_all | 1 | 8.51 ms | 12.69 ms | 16.85 ms | 17.07 ms | 12.59 ms | 79.4 |
| surrealkv | 100 | bench_plain | count_aggregate | 1 | 2.65 ms | 3.52 ms | 4.62 ms | 4.62 ms | 3.61 ms | 277.2 |
| surrealkv | 100 | bench_plain | point_read_x100 | 100 | 44.29 ms | 52.61 ms | 72.51 ms | 74.92 ms | 53.69 ms | 1.9k |
| surrealkv | 100 | bench_plain | merge_point_x100 | 100 | 84.85 ms | 127.19 ms | 162.83 ms | 165.88 ms | 125.39 ms | 797.5 |
| surrealkv | 100 | bench_plain | update_bulk | 1 | 13.86 ms | 17.66 ms | 29.20 ms | 30.57 ms | 19.54 ms | 51.2 |
| surrealkv | 100 | bench_plain | filter_eq | 1 | 5.65 ms | 7.42 ms | 10.04 ms | 10.08 ms | 7.61 ms | 131.4 |
| surrealkv | 100 | bench_plain | filter_range | 1 | 6.08 ms | 7.35 ms | 17.51 ms | 19.37 ms | 8.03 ms | 124.5 |
| surrealkv | 100 | bench_plain | filter_compound | 1 | 3.57 ms | 6.24 ms | 7.27 ms | 7.30 ms | 6.07 ms | 164.7 |
| surrealkv | 100 | bench_idx | insert_batch | 100 | 23.12 ms | 28.80 ms | 42.91 ms | 44.07 ms | 30.09 ms | 3.3k |
| surrealkv | 100 | bench_idx | create_single_x100 | 100 | 298.21 ms | 323.75 ms | 698.10 ms | 721.05 ms | 372.92 ms | 268.2 |
| surrealkv | 100 | bench_idx | delete_all | 100 | 30.25 ms | 46.26 ms | 57.94 ms | 58.27 ms | 46.13 ms | 2.2k |
| surrealkv | 100 | bench_idx | select_all | 1 | 9.77 ms | 12.47 ms | 15.75 ms | 15.79 ms | 12.64 ms | 79.1 |
| surrealkv | 100 | bench_idx | count_aggregate | 1 | 5.07 ms | 6.30 ms | 7.58 ms | 7.60 ms | 6.20 ms | 161.3 |
| surrealkv | 100 | bench_idx | point_read_x100 | 100 | 57.02 ms | 72.66 ms | 91.68 ms | 92.60 ms | 73.58 ms | 1.4k |
| surrealkv | 100 | bench_idx | merge_point_x100 | 100 | 101.04 ms | 131.11 ms | 175.16 ms | 182.13 ms | 130.76 ms | 764.8 |
| surrealkv | 100 | bench_idx | update_bulk | 1 | 14.70 ms | 21.03 ms | 31.06 ms | 31.10 ms | 21.35 ms | 46.8 |
| surrealkv | 100 | bench_idx | filter_eq | 1 | 2.12 ms | 2.82 ms | 4.94 ms | 4.97 ms | 3.04 ms | 328.7 |
| surrealkv | 100 | bench_idx | filter_range | 1 | 2.93 ms | 3.78 ms | 5.58 ms | 5.61 ms | 4.01 ms | 249.4 |
| surrealkv | 100 | bench_idx | filter_compound | 1 | 1.32 ms | 1.98 ms | 5.32 ms | 5.55 ms | 2.22 ms | 451.3 |
| surrealkv | 1000 | bench_plain | insert_batch | 1000 | 107.80 ms | 130.84 ms | 177.84 ms | 178.04 ms | 135.60 ms | 7.4k |
| surrealkv | 1000 | bench_plain | create_single_x100 | 100 | 158.81 ms | 208.61 ms | 232.41 ms | 234.04 ms | 207.59 ms | 481.7 |
| surrealkv | 1000 | bench_plain | delete_all | 1000 | 100.36 ms | 171.37 ms | 227.53 ms | 229.99 ms | 168.62 ms | 5.9k |
| surrealkv | 1000 | bench_plain | select_all | 1 | 69.00 ms | 91.08 ms | 113.19 ms | 113.81 ms | 90.74 ms | 11.0 |
| surrealkv | 1000 | bench_plain | count_aggregate | 1 | 20.69 ms | 24.82 ms | 34.53 ms | 35.33 ms | 25.26 ms | 39.6 |
| surrealkv | 1000 | bench_plain | point_read_x100 | 100 | 46.74 ms | 62.68 ms | 74.87 ms | 74.99 ms | 62.18 ms | 1.6k |
| surrealkv | 1000 | bench_plain | merge_point_x100 | 100 | 85.93 ms | 123.49 ms | 160.07 ms | 163.93 ms | 123.14 ms | 812.1 |
| surrealkv | 1000 | bench_plain | update_bulk | 1 | 125.52 ms | 171.16 ms | 207.17 ms | 208.75 ms | 172.19 ms | 5.8 |
| surrealkv | 1000 | bench_plain | filter_eq | 1 | 33.54 ms | 42.22 ms | 52.57 ms | 53.80 ms | 41.98 ms | 23.8 |
| surrealkv | 1000 | bench_plain | filter_range | 1 | 37.33 ms | 42.53 ms | 62.89 ms | 66.03 ms | 44.64 ms | 22.4 |
| surrealkv | 1000 | bench_plain | filter_compound | 1 | 33.44 ms | 40.21 ms | 48.95 ms | 49.09 ms | 40.14 ms | 24.9 |
| surrealkv | 1000 | bench_idx | insert_batch | 1000 | 254.44 ms | 331.67 ms | 389.75 ms | 390.04 ms | 328.50 ms | 3.0k |
| surrealkv | 1000 | bench_idx | create_single_x100 | 100 | 264.29 ms | 304.64 ms | 344.99 ms | 349.04 ms | 306.09 ms | 326.7 |
| surrealkv | 1000 | bench_idx | delete_all | 1000 | 325.90 ms | 386.33 ms | 429.43 ms | 432.78 ms | 383.60 ms | 2.6k |
| surrealkv | 1000 | bench_idx | select_all | 1 | 81.32 ms | 114.15 ms | 141.08 ms | 142.74 ms | 112.12 ms | 8.9 |
| surrealkv | 1000 | bench_idx | count_aggregate | 1 | 28.43 ms | 31.24 ms | 41.56 ms | 42.26 ms | 32.45 ms | 30.8 |
| surrealkv | 1000 | bench_idx | point_read_x100 | 100 | 50.34 ms | 64.64 ms | 90.83 ms | 92.60 ms | 65.47 ms | 1.5k |
| surrealkv | 1000 | bench_idx | merge_point_x100 | 100 | 98.97 ms | 132.73 ms | 150.69 ms | 151.65 ms | 129.79 ms | 770.5 |
| surrealkv | 1000 | bench_idx | update_bulk | 1 | 137.85 ms | 207.16 ms | 245.10 ms | 245.53 ms | 207.77 ms | 4.8 |
| surrealkv | 1000 | bench_idx | filter_eq | 1 | 10.57 ms | 13.74 ms | 21.03 ms | 21.30 ms | 14.92 ms | 67.0 |
| surrealkv | 1000 | bench_idx | filter_range | 1 | 23.89 ms | 30.83 ms | 40.59 ms | 40.93 ms | 31.34 ms | 31.9 |
| surrealkv | 1000 | bench_idx | filter_compound | 1 | 10.58 ms | 12.39 ms | 15.39 ms | 15.41 ms | 12.51 ms | 79.9 |
| surrealkv | 10000 | bench_plain | insert_batch | 10000 | 1.079 s | 1.660 s | 4.978 s | 6.194 s | 1.785 s | 5.6k |
| surrealkv | 10000 | bench_plain | create_single_x100 | 100 | 280.75 ms | 380.78 ms | 500.60 ms | 503.61 ms | 386.99 ms | 258.4 |
| surrealkv | 10000 | bench_plain | delete_all | 10000 | 3.703 s | 5.771 s | 6.609 s | 6.618 s | 5.546 s | 1.8k |
| surrealkv | 10000 | bench_plain | select_all | 1 | 967.78 ms | 1.195 s | 1.400 s | 1.430 s | 1.181 s | 0.8 |
| surrealkv | 10000 | bench_plain | count_aggregate | 1 | 329.45 ms | 437.77 ms | 508.33 ms | 514.32 ms | 429.37 ms | 2.3 |
| surrealkv | 10000 | bench_plain | point_read_x100 | 100 | 85.48 ms | 114.44 ms | 140.85 ms | 141.27 ms | 116.82 ms | 856.0 |
| surrealkv | 10000 | bench_plain | merge_point_x100 | 100 | 137.47 ms | 176.93 ms | 283.40 ms | 284.43 ms | 187.72 ms | 532.7 |
| surrealkv | 10000 | bench_plain | update_bulk | 1 | 1.014 s | 1.342 s | 6.222 s | 8.128 s | 1.541 s | 0.6 |
| surrealkv | 10000 | bench_plain | filter_eq | 1 | 123.64 ms | 180.22 ms | 218.68 ms | 222.55 ms | 178.51 ms | 5.6 |
| surrealkv | 10000 | bench_plain | filter_range | 1 | 179.71 ms | 256.23 ms | 346.19 ms | 349.21 ms | 256.42 ms | 3.9 |
| surrealkv | 10000 | bench_plain | filter_compound | 1 | 92.18 ms | 117.58 ms | 172.21 ms | 176.50 ms | 122.19 ms | 8.2 |
| surrealkv | 10000 | bench_idx | insert_batch | 10000 | 3.857 s | 5.962 s | 11.430 s | 11.461 s | 6.232 s | 1.6k |
| surrealkv | 10000 | bench_idx | create_single_x100 | 100 | 486.01 ms | 599.46 ms | 1.044 s | 1.074 s | 644.49 ms | 155.2 |
| surrealkv | 10000 | bench_idx | delete_all | 10000 | 5.736 s | 9.777 s | 25.119 s | 28.503 s | 10.038 s | 996.2 |
| surrealkv | 10000 | bench_idx | select_all | 1 | 385.31 ms | 425.67 ms | 521.31 ms | 533.63 ms | 430.51 ms | 2.3 |
| surrealkv | 10000 | bench_idx | count_aggregate | 1 | 99.84 ms | 106.64 ms | 139.10 ms | 148.98 ms | 107.72 ms | 9.3 |
| surrealkv | 10000 | bench_idx | point_read_x100 | 100 | 48.25 ms | 50.85 ms | 67.46 ms | 70.65 ms | 52.15 ms | 1.9k |
| surrealkv | 10000 | bench_idx | merge_point_x100 | 100 | 61.83 ms | 67.72 ms | 129.84 ms | 150.39 ms | 71.27 ms | 1.4k |
| surrealkv | 10000 | bench_idx | update_bulk | 1 | 656.95 ms | 773.29 ms | 2.469 s | 3.119 s | 851.77 ms | 1.2 |
| surrealkv | 10000 | bench_idx | filter_eq | 1 | 38.34 ms | 43.00 ms | 57.57 ms | 57.73 ms | 44.11 ms | 22.7 |
| surrealkv | 10000 | bench_idx | filter_range | 1 | 81.52 ms | 89.46 ms | 114.31 ms | 115.33 ms | 91.91 ms | 10.9 |
| surrealkv | 10000 | bench_idx | filter_compound | 1 | 54.53 ms | 62.72 ms | 93.49 ms | 97.97 ms | 65.34 ms | 15.3 |
| rocksdb | 100 | bench_plain | insert_batch | 100 | 7.26 ms | 8.89 ms | 14.98 ms | 15.69 ms | 9.58 ms | 10.4k |
| rocksdb | 100 | bench_plain | create_single_x100 | 100 | 132.45 ms | 147.87 ms | 165.90 ms | 167.50 ms | 149.10 ms | 670.7 |
| rocksdb | 100 | bench_plain | delete_all | 100 | 17.20 ms | 24.41 ms | 40.68 ms | 41.08 ms | 25.39 ms | 3.9k |
| rocksdb | 100 | bench_plain | select_all | 1 | 2.97 ms | 3.79 ms | 6.81 ms | 6.91 ms | 3.94 ms | 254.1 |
| rocksdb | 100 | bench_plain | count_aggregate | 1 | 271 µs | 444 µs | 922 µs | 950 µs | 484 µs | 2.1k |
| rocksdb | 100 | bench_plain | point_read_x100 | 100 | 18.13 ms | 20.38 ms | 36.15 ms | 36.39 ms | 22.79 ms | 4.4k |
| rocksdb | 100 | bench_plain | merge_point_x100 | 100 | 132.32 ms | 161.00 ms | 696.75 ms | 717.47 ms | 222.68 ms | 449.1 |
| rocksdb | 100 | bench_plain | update_bulk | 1 | 5.81 ms | 9.98 ms | 17.82 ms | 19.00 ms | 10.19 ms | 98.1 |
| rocksdb | 100 | bench_plain | filter_eq | 1 | 705 µs | 1.40 ms | 4.08 ms | 4.80 ms | 1.53 ms | 654.5 |
| rocksdb | 100 | bench_plain | filter_range | 1 | 1.04 ms | 1.41 ms | 2.84 ms | 3.04 ms | 1.50 ms | 665.3 |
| rocksdb | 100 | bench_plain | filter_compound | 1 | 1.06 ms | 1.48 ms | 3.24 ms | 3.45 ms | 1.53 ms | 652.3 |
| rocksdb | 100 | bench_idx | insert_batch | 100 | 14.49 ms | 21.04 ms | 32.92 ms | 34.14 ms | 21.05 ms | 4.7k |
| rocksdb | 100 | bench_idx | create_single_x100 | 100 | 165.77 ms | 200.03 ms | 222.03 ms | 222.44 ms | 198.20 ms | 504.5 |
| rocksdb | 100 | bench_idx | delete_all | 100 | 30.50 ms | 53.59 ms | 63.76 ms | 64.72 ms | 51.53 ms | 1.9k |
| rocksdb | 100 | bench_idx | select_all | 1 | 3.64 ms | 5.45 ms | 7.85 ms | 7.89 ms | 5.51 ms | 181.5 |
| rocksdb | 100 | bench_idx | count_aggregate | 1 | 676 µs | 818 µs | 1.06 ms | 1.07 ms | 837 µs | 1.2k |
| rocksdb | 100 | bench_idx | point_read_x100 | 100 | 26.72 ms | 38.38 ms | 43.54 ms | 43.67 ms | 36.73 ms | 2.7k |
| rocksdb | 100 | bench_idx | merge_point_x100 | 100 | 142.83 ms | 168.28 ms | 192.92 ms | 194.45 ms | 167.71 ms | 596.3 |
| rocksdb | 100 | bench_idx | update_bulk | 1 | 9.69 ms | 14.27 ms | 17.34 ms | 17.78 ms | 13.76 ms | 72.7 |
| rocksdb | 100 | bench_idx | filter_eq | 1 | 851 µs | 1.45 ms | 2.46 ms | 2.54 ms | 1.48 ms | 676.6 |
| rocksdb | 100 | bench_idx | filter_range | 1 | 1.61 ms | 2.60 ms | 4.92 ms | 4.96 ms | 2.74 ms | 364.8 |
| rocksdb | 100 | bench_idx | filter_compound | 1 | 1.06 ms | 1.41 ms | 2.18 ms | 2.27 ms | 1.49 ms | 671.1 |
| rocksdb | 1000 | bench_plain | insert_batch | 1000 | 82.31 ms | 120.38 ms | 173.63 ms | 174.53 ms | 123.72 ms | 8.1k |
| rocksdb | 1000 | bench_plain | create_single_x100 | 100 | 195.13 ms | 232.47 ms | 350.50 ms | 377.94 ms | 237.41 ms | 421.2 |
| rocksdb | 1000 | bench_plain | delete_all | 1000 | 297.99 ms | 400.06 ms | 541.66 ms | 562.73 ms | 400.56 ms | 2.5k |
| rocksdb | 1000 | bench_plain | select_all | 1 | 42.07 ms | 61.61 ms | 87.80 ms | 89.58 ms | 63.30 ms | 15.8 |
| rocksdb | 1000 | bench_plain | count_aggregate | 1 | 3.38 ms | 3.69 ms | 5.35 ms | 5.67 ms | 3.80 ms | 263.0 |
| rocksdb | 1000 | bench_plain | point_read_x100 | 100 | 33.38 ms | 44.04 ms | 66.09 ms | 67.76 ms | 46.02 ms | 2.2k |
| rocksdb | 1000 | bench_plain | merge_point_x100 | 100 | 228.05 ms | 248.84 ms | 283.87 ms | 287.13 ms | 250.68 ms | 398.9 |
| rocksdb | 1000 | bench_plain | update_bulk | 1 | 98.61 ms | 138.75 ms | 194.45 ms | 196.65 ms | 144.22 ms | 6.9 |
| rocksdb | 1000 | bench_plain | filter_eq | 1 | 8.54 ms | 9.94 ms | 13.63 ms | 13.77 ms | 10.06 ms | 99.4 |
| rocksdb | 1000 | bench_plain | filter_range | 1 | 13.88 ms | 19.82 ms | 31.65 ms | 31.91 ms | 20.33 ms | 49.2 |
| rocksdb | 1000 | bench_plain | filter_compound | 1 | 7.47 ms | 11.73 ms | 17.05 ms | 18.41 ms | 11.10 ms | 90.1 |
| rocksdb | 1000 | bench_idx | insert_batch | 1000 | 283.81 ms | 408.24 ms | 519.92 ms | 522.41 ms | 411.72 ms | 2.4k |
| rocksdb | 1000 | bench_idx | create_single_x100 | 100 | 270.42 ms | 327.77 ms | 368.47 ms | 369.73 ms | 331.09 ms | 302.0 |
| rocksdb | 1000 | bench_idx | delete_all | 1000 | 704.91 ms | 923.14 ms | 1.111 s | 1.116 s | 937.55 ms | 1.1k |
| rocksdb | 1000 | bench_idx | select_all | 1 | 53.64 ms | 64.27 ms | 107.16 ms | 108.14 ms | 69.63 ms | 14.4 |
| rocksdb | 1000 | bench_idx | count_aggregate | 1 | 6.40 ms | 7.07 ms | 10.87 ms | 10.91 ms | 7.70 ms | 129.9 |
| rocksdb | 1000 | bench_idx | point_read_x100 | 100 | 53.29 ms | 68.65 ms | 101.85 ms | 105.91 ms | 70.69 ms | 1.4k |
| rocksdb | 1000 | bench_idx | merge_point_x100 | 100 | 247.29 ms | 272.68 ms | 311.55 ms | 313.01 ms | 277.49 ms | 360.4 |
| rocksdb | 1000 | bench_idx | update_bulk | 1 | 120.10 ms | 164.48 ms | 224.22 ms | 224.83 ms | 168.79 ms | 5.9 |
| rocksdb | 1000 | bench_idx | filter_eq | 1 | 7.68 ms | 11.16 ms | 12.54 ms | 12.57 ms | 10.81 ms | 92.5 |
| rocksdb | 1000 | bench_idx | filter_range | 1 | 15.65 ms | 20.06 ms | 34.57 ms | 36.18 ms | 21.54 ms | 46.4 |
| rocksdb | 1000 | bench_idx | filter_compound | 1 | 6.16 ms | 9.98 ms | 14.30 ms | 14.56 ms | 9.88 ms | 101.2 |
| rocksdb | 10000 | bench_plain | insert_batch | 10000 | 736.65 ms | 846.45 ms | 1.814 s | 1.912 s | 948.70 ms | 10.5k |
| rocksdb | 10000 | bench_plain | create_single_x100 | 100 | 133.86 ms | 160.48 ms | 214.43 ms | 222.57 ms | 164.51 ms | 607.9 |
| rocksdb | 10000 | bench_plain | delete_all | 10000 | 2.067 s | 2.538 s | 3.442 s | 3.463 s | 2.673 s | 3.7k |
| rocksdb | 10000 | bench_plain | select_all | 1 | 469.15 ms | 582.18 ms | 679.65 ms | 680.59 ms | 588.93 ms | 1.7 |
| rocksdb | 10000 | bench_plain | count_aggregate | 1 | 63.96 ms | 80.58 ms | 124.74 ms | 127.15 ms | 85.07 ms | 11.8 |
| rocksdb | 10000 | bench_plain | point_read_x100 | 100 | 41.38 ms | 56.27 ms | 73.04 ms | 74.51 ms | 56.40 ms | 1.8k |
| rocksdb | 10000 | bench_plain | merge_point_x100 | 100 | 237.57 ms | 263.36 ms | 717.75 ms | 724.24 ms | 311.84 ms | 320.7 |
| rocksdb | 10000 | bench_plain | update_bulk | 1 | 919.52 ms | 1.133 s | 1.433 s | 1.456 s | 1.170 s | 0.9 |
| rocksdb | 10000 | bench_plain | filter_eq | 1 | 117.94 ms | 169.63 ms | 219.81 ms | 226.41 ms | 168.25 ms | 5.9 |
| rocksdb | 10000 | bench_plain | filter_range | 1 | 210.65 ms | 280.35 ms | 328.71 ms | 328.79 ms | 276.83 ms | 3.6 |
| rocksdb | 10000 | bench_plain | filter_compound | 1 | 99.91 ms | 137.38 ms | 176.93 ms | 182.05 ms | 136.67 ms | 7.3 |
| rocksdb | 10000 | bench_idx | insert_batch | 10000 | 2.587 s | 4.100 s | 5.164 s | 5.205 s | 4.150 s | 2.4k |
| rocksdb | 10000 | bench_idx | create_single_x100 | 100 | 267.89 ms | 317.86 ms | 365.47 ms | 366.91 ms | 318.68 ms | 313.8 |
| rocksdb | 10000 | bench_idx | delete_all | 10000 | 6.543 s | 10.222 s | 11.970 s | 11.984 s | 10.015 s | 998.5 |
| rocksdb | 10000 | bench_idx | select_all | 1 | 529.10 ms | 713.75 ms | 885.17 ms | 887.93 ms | 714.00 ms | 1.4 |
| rocksdb | 10000 | bench_idx | count_aggregate | 1 | 14.29 ms | 20.61 ms | 26.56 ms | 27.16 ms | 20.38 ms | 49.1 |
| rocksdb | 10000 | bench_idx | point_read_x100 | 100 | 74.40 ms | 85.45 ms | 101.26 ms | 101.61 ms | 87.14 ms | 1.1k |
| rocksdb | 10000 | bench_idx | merge_point_x100 | 100 | 288.59 ms | 314.66 ms | 704.16 ms | 707.18 ms | 358.55 ms | 278.9 |
| rocksdb | 10000 | bench_idx | update_bulk | 1 | 1.102 s | 1.425 s | 1.806 s | 1.832 s | 1.440 s | 0.7 |
| rocksdb | 10000 | bench_idx | filter_eq | 1 | 54.78 ms | 66.74 ms | 104.45 ms | 104.50 ms | 70.43 ms | 14.2 |
| rocksdb | 10000 | bench_idx | filter_range | 1 | 119.48 ms | 178.00 ms | 225.26 ms | 229.76 ms | 178.36 ms | 5.6 |
| rocksdb | 10000 | bench_idx | filter_compound | 1 | 37.98 ms | 48.84 ms | 71.64 ms | 73.02 ms | 50.86 ms | 19.7 |

## Notes

```
EXPLAIN n=100 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=100 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=1000 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=1000 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=10000 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=10000 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=100 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=100 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=1000 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=1000 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=10000 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=10000 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=100 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=100 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=1000 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=1000 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```

```
EXPLAIN n=10000 bench_plain (compound filter):
[{attributes: {projections: *}, children: [{attributes: {direction: Forward, pre_decode_filter: yes, predicate: category = 3 AND age >= 30, table: bench_plain}, context: Db, operator: TableScan}], context: Db, operator: SelectProject}]
```

```
EXPLAIN n=10000 bench_idx (compound filter):
[{attributes: {projections: *}, children: [{attributes: {predicate: category = 3 AND age >= 30}, children: [{attributes: {table: bench_idx}, children: [{children: [{attributes: {access: = 3, index: idx_bench_idx_cat}, context: Db, operator: BitmapIndexScan}, {attributes: {access: [3] MoreThanEqual 30, index: idx_bench_idx_cat_age}, context: Db, operator: BitmapIndexScan}], context: Db, operator: BitmapAnd}], context: Db, operator: BitmapResolve}], context: Db, expressions: [{role: predicate, sql...
```
