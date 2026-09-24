#!/usr/bin/env bash
# Godot'u ekransız çalıştırıp duman testini koşturur.
# Kullanım: tools/run_tests.sh   (GODOT değişkeniyle farklı bir Godot yolu verilebilir)
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT_VERSION="4.6-stable"
GODOT="${GODOT:-tools/bin/godot}"

if [ ! -x "$GODOT" ]; then
	echo "Godot $GODOT_VERSION indiriliyor..."
	mkdir -p tools/bin
	curl -sSL -o tools/bin/godot.zip \
		"https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	unzip -oq tools/bin/godot.zip -d tools/bin
	mv "tools/bin/Godot_v${GODOT_VERSION}_linux.x86_64" tools/bin/godot
	rm tools/bin/godot.zip
fi

log="$(mktemp)"
"$GODOT" --headless --path . --import 2>&1 | tee "$log"
"$GODOT" --headless --path . -s res://tests/smoke_test.gd 2>&1 | tee -a "$log"

if grep -qE "SCRIPT ERROR|Parse Error|Failed to load" "$log"; then
	echo "Hata: Godot çıktısında betik hatası bulundu." >&2
	exit 1
fi
