#!/usr/bin/env bash

set -euo pipefail

CSSDIR="$HOME/css-serverfiles"
TF2DIR="$HOME/tf2-serverfiles"

STEAMCMD=""

prepare() {
    echo "=== Counter-Strike: Source Dedicated Server ==="
    echo

    # Szukamy SteamCMD
    if command -v steamcmd >/dev/null 2>&1; then
        STEAMCMD="$(command -v steamcmd)"
    elif [ -x "$HOME/steamcmd/steamcmd.sh" ]; then
        STEAMCMD="$HOME/steamcmd/steamcmd.sh"
    else
        echo "BŁĄD: Nie znaleziono SteamCMD."
        echo
        echo "Zainstaluj SteamCMD i uruchom skrypt ponownie."
        exit 1
    fi

    echo "SteamCMD: $STEAMCMD"
    echo "CSS:      $CSSDIR"
    echo "TF2:      $TF2DIR"
    echo
}

download_css() {
    echo "=== Pobieranie Counter-Strike: Source ==="

    if [ -d "$CSSDIR" ]; then
        echo "BŁĄD: $CSSDIR już istnieje."
        exit 1
    fi

    "$STEAMCMD" \
        +force_install_dir "$CSSDIR" \
        +login anonymous \
        +app_update 232330 validate \
        +quit

    echo
    echo "CSS został pobrany."
}

download_tf2() {
    echo "=== Pobieranie TF2 jako źródła binariów 64-bit ==="

    if [ -d "$TF2DIR" ]; then
        echo "$TF2DIR już istnieje. Używam istniejącej instalacji."
        return
    fi

    "$STEAMCMD" \
        +force_install_dir "$TF2DIR" \
        +login anonymous \
        +app_update 232250 validate \
        +quit

    echo
    echo "TF2 zostało pobrane."
}

copy_64bit_binaries() {
    echo "=== Kopiowanie binariów 64-bit ==="

    if [ ! -f "$TF2DIR/bin/linux64/libsteam_api.so" ]; then
        echo "BŁĄD: Nie znaleziono:"
        echo "$TF2DIR/bin/linux64/libsteam_api.so"
        exit 1
    fi

    if [ ! -f "$TF2DIR/srcds_linux64" ]; then
        echo "BŁĄD: Nie znaleziono:"
        echo "$TF2DIR/srcds_linux64"
        exit 1
    fi

    if [ ! -f "$TF2DIR/srcds_run_64" ]; then
        echo "BŁĄD: Nie znaleziono:"
        echo "$TF2DIR/srcds_run_64"
        exit 1
    fi

    echo "Kopiowanie libsteam_api.so..."

    cp -a \
        "$TF2DIR/bin/linux64/libsteam_api.so" \
        "$CSSDIR/bin/linux64/"

    echo "Kopiowanie srcds_linux64..."

    cp -a \
        "$TF2DIR/srcds_linux64" \
        "$CSSDIR/"

    echo "Kopiowanie srcds_run_64..."

    cp -a \
        "$TF2DIR/srcds_run_64" \
        "$CSSDIR/"

    chmod +x \
        "$CSSDIR/srcds_linux64" \
        "$CSSDIR/srcds_run_64"

    echo "Binariów 64-bit skopiowane."
}

create_symlinks() {
    echo "=== Tworzenie symlinków ==="

    cd "$CSSDIR/bin/linux64"

    for file in *_srv.so; do
        [ -e "$file" ] || continue

        target="${file/_srv/}"

        echo "$target -> $file"
        ln -sf "$file" "$target"
    done
}

setup_steamclient() {
    echo "=== Konfiguracja steamclient.so ==="

    local steamclient

    steamclient="$(
        find "$HOME" \
            -type f \
            -path '*/linux64/steamclient.so' \
            2>/dev/null |
        head -n 1
    )"

    if [ -z "$steamclient" ]; then
        echo "BŁĄD: Nie znaleziono 64-bitowego steamclient.so."
        exit 1
    fi

    echo "Znaleziono:"
    echo "$steamclient"

    mkdir -p "$HOME/.steam/sdk64"

    ln -sf \
        "$steamclient" \
        "$HOME/.steam/sdk64/steamclient.so"

    ln -sf \
        "$steamclient" \
        "$CSSDIR/bin/linux64/steamclient.so"
}

remove_tf2() {
    echo "=== Usuwanie plików TF2 ==="

    if [ -f "$CSSDIR/srcds_linux64" ]; then
        rm -rf "$TF2DIR"
        echo "TF2 usunięte."
    else
        echo "Nie usuwam TF2 - brakuje srcds_linux64 w CSS."
        exit 1
    fi
}

show_result() {
    echo
    echo "=================================================="
    echo
    echo "Counter-Strike: Source 64-bit został zainstalowany."
    echo
    echo "Katalog:"
    echo "  $CSSDIR"
    echo
    echo "Binariów:"
    echo "  $CSSDIR/srcds_linux64"
    echo "  $CSSDIR/srcds_run_64"
    echo
    echo "Uruchomienie:"
    echo
    echo "  cd $CSSDIR"
    echo "  ./srcds_run_64 -game cstrike +map de_dust2 -debug"
    echo
    echo "=================================================="
}

main() {
    prepare
    download_css
    download_tf2
    copy_64bit_binaries
    create_symlinks
    setup_steamclient
    remove_tf2
    show_result
}

main "$@"