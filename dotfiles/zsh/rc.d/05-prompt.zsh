#!/bin/zsh

# `znap prompt` can autoload our prompt function, because in 04-env.zsh, we
# added its parent dir to our $fpath. We reduce startup time by making the 
# left side of the primary prompt visible *immediately.*
znap prompt fruz
