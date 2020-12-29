
#!/bin/bash
set -e

PASSWORD=${1?"Usage: $0 <password>"}

set -v

# Set user password
echo pi:$PASSWORD | sudo chpasswd
