#!/usr/bin/env bash

ip=$(ip a show eth0 | grep 'inet.*/.*brd' | egrep -o '[0-9].*/')
ip=${ip/\//}
echo "IP: $ip"

# allow write permission for users Windows
path_w_host="/mnt/c/WINDOWS/system32/drivers/etc/hosts"
path_tmp_host="/tmp/hosts"
current_docker_value=$(grep "docker" $path_w_host)

if [[ "$current_docker_value" != "" ]]; then
  echo "replace: \"$ip docker\""
  cp $path_w_host $path_tmp_host
  sed -i "s/.* docker/$ip docker/" $path_tmp_host
  cp $path_tmp_host $path_w_host
else
  echo "add: \"$ip docker\""
  echo "$ip docker" >> $path_w_host
fi
