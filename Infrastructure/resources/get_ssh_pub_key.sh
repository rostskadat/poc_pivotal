#!/bin/sh
# Change the contents of this output to get the environment variables
# of interest. The output must be valid JSON, with strings for both
# keys and values.
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -q -t rsa -b 2048 -f ~/.ssh/id_rsa -N --
fi
cat <<EOF
{
  "ssh_public_key": "$(cat ~/.ssh/id_rsa.pub)",
}
EOF
