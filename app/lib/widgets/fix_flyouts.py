import re
from pathlib import Path

f = Path(r"c:\Users\Silver\Downloads\silver-os\50_IDEAS\Apps\Hydrop_Notes\app\lib\widgets\drawing_toolbar.dart")
content = f.read_text(encoding="utf-8")

# We want to replace all 4 instances of the switch block
old_switch = re.compile(
r"    switch \(widget\.dock\) \{\n\s*case ToolbarDock\.left:\n\s*left = widget\.origin\.dx \+ widget\.size\.width \+ 8;\n\s*top = widget\.origin\.dy;\n\s*isPanelHorizontal = true;\n\s*break;\n\s*case ToolbarDock\.right:\n\s*right = \(screenWidth - widget\.origin\.dx\) \+ 8;\n\s*top = widget\.origin\.dy;\n\s*isPanelHorizontal = true;\n\s*break;\n\s*case ToolbarDock\.top:\n\s*left = widget\.origin\.dx;\n\s*top = widget\.origin\.dy \+ widget\.size\.height \+ 8;\n\s*isPanelHorizontal = false;\n\s*break;\n\s*case ToolbarDock\.bottom:\n\s*left = widget\.origin\.dx;\n\s*bottom = \(screenHeight - widget\.origin\.dy\) \+ 8;\n\s*isPanelHorizontal = false;\n\s*break;\n\s*\}"
)

new_switch = """    switch (widget.dock) {
      case ToolbarDock.left:
        left = widget.origin.dx + widget.size.width + 8;
        top = widget.origin.dy + widget.size.height / 2;
        isPanelHorizontal = true;
        break;
      case ToolbarDock.right:
        right = (screenWidth - widget.origin.dx) + 8;
        top = widget.origin.dy + widget.size.height / 2;
        isPanelHorizontal = true;
        break;
      case ToolbarDock.top:
        left = widget.origin.dx + widget.size.width / 2;
        top = widget.origin.dy + widget.size.height + 8;
        isPanelHorizontal = false;
        break;
      case ToolbarDock.bottom:
        left = widget.origin.dx + widget.size.width / 2;
        bottom = (screenHeight - widget.origin.dy) + 8;
        isPanelHorizontal = false;
        break;
    }"""

content = old_switch.sub(new_switch, content)

# Now we want to wrap the ScaleTransition in a FractionalTranslation
# The easiest way is to find:
#               child: ScaleTransition(
#                 scale: _expandAnimation,
# and replace with:
#               child: FractionalTranslation(
#                 translation: widget.dock == ToolbarDock.top || widget.dock == ToolbarDock.bottom
#                     ? const Offset(-0.5, 0)
#                     : const Offset(0, -0.5),
#                 child: ScaleTransition(
#                   scale: _expandAnimation,

old_scale = """              child: ScaleTransition(
                scale: _expandAnimation,"""

new_scale = """              child: FractionalTranslation(
                translation: widget.dock == ToolbarDock.top || widget.dock == ToolbarDock.bottom
                    ? const Offset(-0.5, 0)
                    : const Offset(0, -0.5),
                child: ScaleTransition(
                  scale: _expandAnimation,"""

content = content.replace(old_scale, new_scale)

# And then we need to add the closing bracket for FractionalTranslation
# It should be added right after the `),` of the `child: HydropTheme.of(context).applyBackdrop(...)` or `Material(...)` block.
# Wait, let's just find the `ScaleTransition(...)` end.
# Actually, the ScaleTransition has an alignment:
# alignment: ... Alignment.bottomCenter)),
# child: Material(
#   ...
# )
# ),
# Let's find:
#                     borderRadius: BorderRadius.circular(24),
#                   ),
#                 ),
#               ),
#             ),
#           ),

old_end = """                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ],"""

new_end = """                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              ),
            ),
          ),
        ],"""

content = content.replace(old_end, new_end)

f.write_text(content, encoding="utf-8")
print("Fixed flyouts.")
