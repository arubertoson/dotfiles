#
# Utils
#
# Fonts
# xset +fp $HOME/.fonts &
# xset fp rehash &
# fc-cache -fv &

# Powersaving
# xset s off &
# xset s noblank &
# xset s noexpose &
# xset c on &
# xset -dpms &
# Wallpaper


# Window compositor
compton -b \
  --config /dev/null \
  --backend glx \
  --glx-no-stencil \
  --glx-no-rebind-pixmap \
  --glx-swap-method 3 \
  --xrender-sync \
  --xrender-sync-fence \
  --vsync opengl-swc \
  --vsync-use-glfinish \
  --unredir-if-possible \
  --paint-on-overlay \
  --sw-opti &

# fix monitors
# NOTE: On monitor weirdness look here!
source xmonitors
xrandr --output $EXTERNAL_MONITOR --mode 1920x1080 --pos 0x0 \
       --output $PRIMARY_MONITOR --mode 1920x1200 --pos 1920x0
feh --bg-scale "$LOCAL_ETC/wallpapers/gradient.jpg"

# 
# Mouse
#
# Change cursor look & autohide cursor
xsetroot -cursor_name left_ptr
unclutter &

# Start emacs daemon
emacs --daemon &

#
# Window Manager
#


# main
sxhkd &
bspwm
