#!/bin/sh
gcc -o server StringServer.c
gcc -o send StringSend.c
./send Hello#OS#World$ &
./server


