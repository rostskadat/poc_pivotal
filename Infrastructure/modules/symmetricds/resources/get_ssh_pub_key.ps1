#!/bin/sh
# Change the contents of this output to get the environment variables
# of interest. The output must be valid JSON, with strings for both
# keys and values.
if (-not(Test-Path -Path $HOME\.ssh\id_rsa -PathType Leaf)) {
  ssh-keygen -q -t rsa -b 2048 -f $HOME\.ssh\id_rsa -N --
}
$ssh_public_key = Get-Content $HOME\.ssh\id_rsa.pub
ConvertTo-Json @{
  ssh_public_key = $ssh_public_key.ToString()
}
