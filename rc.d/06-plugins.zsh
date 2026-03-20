##
# Plugins
#

# Add the plugins you want to use here.
# For more info on each plugin, visit its repo at github.com/<plugin>
# -a sets the variable's type to array.
local -a plugins=(
    marlonrichert/zcolors

    jeffreytse/zsh-vi-mode              # Vi mode
    hlissner/zsh-autopair               # Auto-pair quotes and parenthesis
    adrieankhisbe/zsh-quiet-accept-line # run comands without outputting to the prompt

    zsh-users/zsh-completions 		# Inline suggestions
    zsh-users/zsh-autosuggestions       # Inline suggestions
    zsh-users/zsh-syntax-highlighting   # Command-line syntax highlighting
)


# Speed up the first startup by cloning all plugins in parallel.
# This won't clone plugins that we already have.
znap clone $plugins

# Load each plugin, one at a time.
local p=
for p in $plugins; do
  file_path="$(dirname $(realpath $0))/conf.plug/${p#*/}.zsh"

  # Check if the file exists and source it if it does
  if [[ -f $file_path ]]; then
      source $file_path
  fi

  # Since fzf is not zsh plugin we need to handle it with more care,
  # we're only calling the plug conf file and hanlding the setup there.
  if [[ "$p" == *"fzf"* ]]; then
      continue
  fi

  znap source $p
done

znap eval zcolors zcolors
