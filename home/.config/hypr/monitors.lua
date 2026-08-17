local gdk_scale = 2

hl.env("GDK_SCALE", tostring(gdk_scale))

hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})

hl.monitor({
  output = "desc:LG Electronics LG FHD 504TFXX0F642",
  mode = "1920x1080@100",
  position = "auto-center-left",
  scale = 1,
})

hl.monitor({
  output = "eDP-1",
  mode = "2880x1920@120",
  position = "auto-center-right",
  scale = 1.6,
})
