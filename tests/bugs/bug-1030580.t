#!/bin/bash

. $(dirname $0)/../include.rc
. $(dirname $0)/../volume.rc

cleanup;

function write_to_file {
    dd of=$M0/1 if=/dev/zero bs=1M count=128 oflag=append 2>&1 >/dev/null
}

function cumulative_stat_count {
    echo "$1" | grep "Cumulative Stats:" | wc -l
}

function incremental_stat_count {
    echo "$1" | grep "Interval$2Stats:" | wc -l
}

TEST glusterd
TEST pidof glusterd
TEST $CLI volume create $V0 replica 2 $H0:$B0/${V0}0 $H0:$B0/${V0}1
TEST $CLI volume start $V0
TEST $CLI volume profile $V0 start
TEST glusterfs --volfile-id=/$V0 --volfile-server=$H0 $M0 --attribute-timeout=0 --entry-timeout=0

# Verify 'volume profile info' prints both cumulative and incremental stats
write_to_file &
wait
output=$($CLI volume profile $V0 info)
EXPECT 2 cumulative_stat_count "$output"
EXPECT 2 incremental_stat_count "$output" ' 0 '

# Verify 'volume profile info incremental' prints incremental stats only
write_to_file &
wait
output=$($CLI volume profile $V0 info incremental)
EXPECT 0 cumulative_stat_count "$output"
EXPECT 2 incremental_stat_count "$output" ' 1 '

# Verify 'volume profile info cumulative' prints cumulative stats only
write_to_file &
wait
output=$($CLI volume profile $V0 info cumulative)
EXPECT 2 cumulative_stat_count "$output"
EXPECT 0 incremental_stat_count "$output" '.*'

# Verify the 'volume profile info cumulative' command above didn't alter
# the interval id
write_to_file &
wait
output=$($CLI volume profile $V0 info incremental)
EXPECT 0 cumulative_stat_count "$output"
EXPECT 2 incremental_stat_count "$output" ' 2 '

cleanup;
