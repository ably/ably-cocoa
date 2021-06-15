#!/bin/bash

set -e

# clear directory
rm -rf ../Source/include/Ably
mkdir ../Source/include/Ably


#symlink Source directory
find ../Source -type f -and -name "*.h" -exec ln -s "../../{}" ../Source/include/Ably \;

#symlink SocketRocket directory
find ../SocketRocket/SocketRocket -type f -and -name "*.h" -exec ln -s "../../{}" ../Source/include/Ably \;