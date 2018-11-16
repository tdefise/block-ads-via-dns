#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# display date
date

# Set tempfiles
# All_domains will contain all domains from all lists, but also duplicates and ones which are whitelisted
all_domains=$(mktemp)
# Like above, but no duplicates or whitelisted URLs
all_domains_uniq=$(mktemp)
# We don't write directly to the zonefile. Instead to this temp file and copy it to the right directory afterwards
zonefile=$(mktemp)

# StevenBlack GitHub Hosts
# Uncomment ONE line containing the filter you want to apply
# See https://github.com/StevenBlack/hosts for more combinations
wget -q -O StevenBlack-hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts

# Filter out localhost and broadcast
grep '^0.0.0.0' StevenBlack-hosts | grep -v -e '127.0.0.1|255.255.255.255|::1' | cut -d " " -f 2 >> $all_domains

# Filter out comments and empty lines
egrep -v -e '^$|#' $all_domains | sort | uniq  > $all_domains_uniq

# Add zone information
sed -r 's/(.*)/zone "\1" {type master; file "\/etc\/bind\/db.blocked";};/' $all_domains_uniq > $zonefile

# Copy temp file to right directory
# This is for Debian 8, might differ on other systems
cp $zonefile /etc/bind/named.conf.blocked

# Remove all tempfiles
rm $all_domains $all_domains_uniq $zonefile StevenBlack-hosts

# Restart bind
service bind9 stop
service bind9 start

# For logfile
echo -e 'done\n\n'
