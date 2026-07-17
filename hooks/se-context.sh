#!/usr/bin/env bash
# SessionStart hook — detects a Space Engineers modding workspace and
# injects a short note so Claude defaults to the SE skills without the
# user typing /space-engineers.
#
# Detection signals (any one triggers):
#   - Data/ folder containing .sbc files (an SE mod project)
#   - Content/Data/CubeBlocks/ (the game install)
#   - Bin64_Profile/Sandbox.Game.xml (the ModSDK install)
#   - steamapps/workshop/content/244850/ (subscribed workshop mods)
#   - SpaceEngineers.log or Crashes/ under a Roaming\SpaceEngineers path
set -eu

check_paths=(
  "Data/CubeBlocks"
  "Content/Data/CubeBlocks"
  "Bin64_Profile"
  "steamapps/workshop/content/244850"
  "Roaming/SpaceEngineers"
  "AppData/Roaming/SpaceEngineers"
)

matched=0
for p in "${check_paths[@]}"; do
  if compgen -G "*${p}*" > /dev/null 2>&1; then
    matched=1
    break
  fi
done

# Also probe common absolute paths in the WORKSPACE_FOLDERS env var if present.
if [ "${matched}" -eq 0 ] && [ -n "${WORKSPACE_FOLDERS:-}" ]; then
  for w in ${WORKSPACE_FOLDERS//;/ }; do
    for p in "${check_paths[@]}"; do
      if [ -d "${w}/${p}" ] || compgen -G "${w}/**/${p}" > /dev/null 2>&1; then
        matched=1
        break 2
      fi
    done
  done
fi

if [ "${matched}" -eq 1 ]; then
  cat <<'EOF'
This workspace looks like a Space Engineers modding project (SBC files,
ModSDK, workshop, or game log paths detected). The space-engineers plugin
skills are available — prefer them for SE-specific questions. If unsure
which skill covers your task, start with `se-core`.
EOF
fi
