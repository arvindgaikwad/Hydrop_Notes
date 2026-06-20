import re
from pathlib import Path

f = Path(r"c:\Users\Silver\Downloads\silver-os\50_IDEAS\Apps\Hydrop_Notes\app\lib\widgets\drawing_toolbar.dart")
content = f.read_text(encoding="utf-8")

# To be safe, we will just count the number of closing brackets for all `Positioned` blocks that contain `FractionalTranslation`.
# It's much easier to just do:
content = content.replace("""                    borderRadius: BorderRadius.circular(
                      HydropTheme.of(context).radiusXl,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],""", """                    borderRadius: BorderRadius.circular(
                      HydropTheme.of(context).radiusXl,
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
        ],""")

f.write_text(content, encoding="utf-8")
print("Fixed EraserFlyout.")
