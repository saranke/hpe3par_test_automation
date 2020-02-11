#!/bin/bash
FILES=$1/*
for f in $FILES
do
  if [ -d "$f" ]
    then
        for ff in $f/*
        do      
            echo "Processing $ff"
            sed -i "s/\['ansible_default_ipv4'\]\['address'\]/['ansible_eth1']['ipv4']['address']/g"  $ff
        done
  else
  	echo "Processing $f file..."
	  # take action on each file. $f store current file name
	  #cat $f
	  #sed -i "s/['ansible_default_ipv4']['address']/['ansible_eth1']['ipv4']['address']/g"  $f
          sed -i "s/\['ansible_default_ipv4'\]\['address'\]/['ansible_eth1']['ipv4']['address']/g"  $f
  fi
done
