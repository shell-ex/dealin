dealin
======

Do you want to run sed only on special field? Do you want run awk on part range?
Yes, that's what you want!

With `dealin`, you can run shell text processing programs on part of line.

Status
------

Ruby version: works
C version: not start yet

Usage
-----

    dealin [-Fsep] -fnum[,num] command ...

    # upper field 2
    dealin -f2 tr a-z A-Z file.txt

    # remove ext name in ls -l result
    ls -l | dealin -f9 sed 's/\..*$//'

    # transform ip to country in field 2
    cat data.txt | dealin -f2 ./ip2country.rb

    # run awk in part area
    cat data.txt | dealin '/\(.*?\)/' awk '...'


