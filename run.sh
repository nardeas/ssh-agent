#!/bin/bash
# Copyright (c) Andreas Urbanski, 2016
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Output colors
underline='\033[4;37m'
purple='\033[0;35m'
bold='\033[1;37m'
green='\033[0;32m'
cyan='\033[0;36m'
red='\033[0;31m'
nc='\033[0m'

# To override the default docker command e.g. to use podman
# export the following environment variable
docker=${docker:-docker}

# To override the default and use the docker hub image,
# uncomment or export the following environment variable
# N.B. you will need to have previously done a docker pull of the image
# image=nardeas/ssh-agent

# Find image id
image=$($docker images|grep ${image:-docker-ssh-agent}|awk '{print $1}')

# Find agent container id
id=$($docker ps -a|grep ssh-agent|awk '{print $1}')

# Stop command
if [ "$1" == "-s" ] && [ $id ]; then
  echo -e "Removing ssh-keys..."
  $docker run --rm --volumes-from=ssh-agent -it ${image} ssh-add -D
  echo -e "Stopping ssh-agent container..."
  $docker rm -f $id
  exit
fi

# Build image if not available
if [ -z $image ]; then
  echo -e "${bold}The image for docker-ssh-agent has not been built.${nc}"
  echo -e "Building image..."
  $docker build -t docker-ssh-agent:latest -f Dockerfile .
  echo -e "${cyan}Image built.${nc}"
fi

# If container is already present, exit.
if [ $id ]; then
  echo -e "A container named 'ssh-agent' is already present."
  echo -e "Do you wish to stop and remove it? (y/N): "
  read input

  if [ "$input" == "y" ]; then
    echo -e "Removing SSH keys..."
    $docker run --rm --volumes-from=ssh-agent -it ${image} ssh-add -D
    echo -e "Stopping ssh-agent container..."
    $docker rm -f $id
    echo -e "${red}Stopped.${nc}"
  fi

  exit
fi

# Run ssh-agent
echo -e "${bold}Launching ssh-agent container...${nc}"
$docker run -d --name=ssh-agent ${image}

echo -e "Adding your ssh keys to the ssh-agent container..."
$docker run --rm --volumes-from=ssh-agent -v ~/.ssh:/.ssh:ro -it ${image} ssh-add /root/.ssh/${1:-id_rsa}

echo -e "${green}ssh-agent is now ready to use.${nc}"
