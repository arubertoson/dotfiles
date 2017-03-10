#
# Init Zplug
#

export ZPLUG_HOME="${LOCAL_SHARE}/zplug"
export ZPLUG_THREADS=8
export ZPLUG_CONFIG_DIR="${XDG_CONFIG_HOME}/zplug"
export ZPLUG_LOADFILE="${ZPLUG_CONFIG_DIR}/packages.zsh"
export ZPLUG_CACHE_DIR="${XDG_CACHE_HOME}/zplug"

[[ -d $ZPLUG_HOME ]] || curl -sL zplug.sh/installer | zsh

# Change default path of zplugs
if [[ -d $ZPLUG_HOME ]]; then
  source $ZPLUG_HOME/init.zsh
  zplug check || zplug install
  zplug load --verbose
fi
