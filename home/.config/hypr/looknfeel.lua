hl.curve("myBezier", {
  type = "bezier",
  points = {
    { 0.05, 0.9 },
    { 0.1, 1.05 },
  },
})

for _, leaf in ipairs({
  "global",
  "windows",
  "windowsIn",
  "windowsOut",
  "layers",
  "layersIn",
  "layersOut",
  "fade",
  "fadeIn",
  "fadeOut",
  "fadeLayersIn",
  "fadeLayersOut",
  "border",
  "borderangle",
  "workspaces",
  "specialWorkspace",
}) do
  hl.animation({
    leaf = leaf,
    enabled = true,
    speed = 0.5,
    bezier = "myBezier",
  })
end
