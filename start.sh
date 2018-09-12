#!/bin/bash

kill -9 $(pidof recpt1)
kill -9 $(pidof ruby main.rb)
kill -9 $(pidof ruby watch.rb)


cd /home/pi/home-tv-client/lib
cd lib && ruby main.rb &
cd lib && ruby watch.rb &
recpt1 --device /dev/px4video3 --b25 --strip --sid hd --http 8888 &

exit 0
