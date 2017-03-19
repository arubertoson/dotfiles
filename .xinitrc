# TODO: Compton launch file
#       The current state of this file is a mess and needs proper refactor
#       whihc will be performed on a new system.

# Reference Code for refactor {{
# compton -bcCGf \
# --config /dev/null \
# --backend xr_glx_hybrid \
# -i 1.0 --inactive-dim 0.2 \

#compton -b --config ${HOME}/.config/compton/compton.conf
#compton -b --config ${HOME}/.config/compton/compton_default.conf

#--xrender-sync \
#--vsync opengl-swc \
# compton -bcCGf \
#    --config /dev/null \
#    --backend xr_glx_hybrid \
#    --glx-no-stencil \
#    --glx-no-rebind-pixmap \
#    --glx-swap-method undefined \
#    --xrender-sync-fence \
#    --vsync drm \
#    --vsync-use-glfinish --dbe \
#    --unredir-if-possible \
#    --paint-on-overlay \
#    --use-ewmh-active-win \
#    --sw-opti \
#    --mark-wmwin-focused \
#    --inactive-dim 0.2 \
#    --inactive-dim-fixed &
# compton -b &
# end of reference code }}}

compton -bcCGF \
--backend xr_glx_hybrid \
--glx-no-stencil \
--glx-no-rebind-pixmap \
--glx-swap-method undefined \
--xrender-sync \
--xrender-sync-fence \
--vsync drm \
--vsync-use-glfinish \
--unredir-if-possible \
--paint-on-overlay \
--sw-opti &


# Fix screen positions, get screen info from xrandr
source xmonitors
xrandr --output $EXTERNAL_MONITOR --mode 1920x1080 --pos 0x0 \
       --output $PRIMARY_MONITOR --mode 1920x1200 --pos 1920x0

# Set cursor to pointer instead of x 
xsetroot -cursor_name left_ptr
# Hide Mouse
unclutter &
# WM
sxhkd &
exec bspwm
