# Counter-Strike: Source 64-bit w Dockerze

Obraz instaluje SteamCMD, serwer CS:S oraz pliki potrzebne do uruchomienia go
w trybie 64-bitowym. Po uruchomieniu kontenera serwer startuje automatycznie.

## Budowanie

Pobieranie plików CS:S i TF2 odbywa się podczas budowania, dlatego pierwszy
build może potrwać kilka minut i wymaga kilku GB wolnego miejsca:

```bash
docker build -t css-server .
```

## Uruchomienie

```bash
docker run --rm -it \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -p 27020:27020/udp \
  --name css-server \
  css-server
```

Domyślnie serwer uruchamia mapę `de_dust2`, ma 16 slotów, port `27015`
i tickrate `66`. Ustawienia można zmienić zmiennymi środowiskowymi:

```bash
docker run --rm -it \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -e CSS_MAP=de_inferno \
  -e CSS_MAXPLAYERS=24 \
  -e CSS_PORT=27015 \
  -e CSS_TICKRATE=100 \
  --name css-server \
  css-server
```

Dodatkowe parametry SRCDS podaje się po nazwie obrazu, na przykład:

```bash
docker run --rm -it \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  css-server +hostname "Moj serwer CSS" +sv_lan 0
```

Własny `server.cfg` można podmontować bez zasłaniania pozostałych plików gry:

```bash
docker run --rm -it \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -v "$(pwd)/server.cfg:/home/steam/css-serverfiles/cstrike/cfg/server.cfg:ro" \
  css-server
```
