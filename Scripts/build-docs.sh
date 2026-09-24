#!/usr/bin/env bash
# Document every implemented pair, models first, from previously compiled modules.
set -euo pipefail
modules="${1:?Usage: bash Scripts/build-docs.sh MODULES_DIRECTORY OUTPUT_DIRECTORY [TARGET]}"
output="${2:?Supply a new output directory}"
if [[ -e "$output" ]]; then
  echo "Output already exists: $output. Supply a new directory." >&2
  exit 1
fi
if [[ "$(uname -s)" == Darwin ]]; then
  target="${3:-$(uname -m)-apple-ios26.0-simulator}"
  extract=(xcrun swift-symbolgraph-extract -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)")
  docc=(xcrun docc)
else
  target="${3:-aarch64-unknown-linux-gnu}"
  extract=(swift-symbolgraph-extract)
  docc=(docc)
fi
mkdir -p "$output/module-cache"
archives=()
for catalog in Sources/*Models/*.docc; do
  [[ -d "$catalog" ]] || { echo 'No implemented model catalogs.' >&2; exit 1; }
  models="$(basename "$(dirname "$catalog")")"
  sdk="${models%Models}"
  for module in "$models" "$sdk"; do
    mkdir -p "$output/$module-symbols"
    "${extract[@]}" -module-name "$module" -target "$target" -I "$modules" \
      -module-cache-path "$output/module-cache" -output-dir "$output/$module-symbols" \
      -minimum-access-level public
    dependencies=()
    if [[ "$module" == "$sdk" ]]; then
      dependencies=(--dependency "$output/$models.doccarchive")
    fi
    "${docc[@]}" convert "Sources/$module/$module.docc" \
      --additional-symbol-graph-dir "$output/$module-symbols" \
      --output-dir "$output/$module.doccarchive" \
      --enable-experimental-external-link-support --warnings-as-errors \
      ${dependencies[@]+"${dependencies[@]}"}
    archives+=("$output/$module.doccarchive")
  done
done
"${docc[@]}" merge "${archives[@]}" --synthesized-landing-page-name swift-congress \
  --synthesized-landing-page-kind Package --output-path "$output/merged.doccarchive"
"${docc[@]}" process-archive transform-for-static-hosting "$output/merged.doccarchive" \
  --output-path "$output/site" --hosting-base-path swift-congress

# The archive's app shell has no root route under the Pages subpath.
cat > "$output/site/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=documentation/">
    <link rel="canonical" href="https://kalebcooper.github.io/swift-congress/documentation/">
    <title>swift-congress</title>
  </head>
  <body>
    <p>Redirecting to the <a href="documentation/">swift-congress documentation</a>.</p>
  </body>
</html>
HTML
