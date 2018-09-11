#!/bin/bash

cd /home/pi/home-tv-client/lib
ruby main.rb &
ruby watch.rb &
recpt1 --device /dev/px4video3 --b25 --strip --sid hd --http 8888 &

exit 0
