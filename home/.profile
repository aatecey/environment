if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
source ~/dev/environment/custom/environment

. "$HOME/.local/share/../bin/env"
