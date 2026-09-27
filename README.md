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

Najprościej uruchomić serwer przez Docker Compose, który publikuje wszystkie
potrzebne porty:

```bash
docker compose up -d
docker compose logs -f
```

Zatrzymanie serwera:

```bash
docker compose down
```

Podłączenie do interaktywnej konsoli uruchomionego serwera:

```bash
docker compose attach css-server
```

W konsoli można wpisywać polecenia SRCDS, na przykład `status` lub
`meta version`. Aby odłączyć konsolę bez zatrzymywania serwera, należy nacisnąć
kolejno `Ctrl+P`, a następnie `Ctrl+Q`. Nie należy używać `Ctrl+C`, ponieważ
zatrzyma ono serwer.

Alternatywnie można użyć bezpośrednio `docker run`:

```bash
docker run --rm -it \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -p 27020:27020/udp \
  --name css-server \
  css-server
```

Samo `EXPOSE` zapisane w obrazie nie publikuje portu. Przy ręcznym uruchamianiu
konieczne jest podanie co najmniej `-p 27015:27015/udp`.

## Windows i WSL2

Jeśli Docker Engine działa bezpośrednio w WSL2, w konsoli CS:S na Windowsie
połącz się z adresem WSL, a nie adresem kontenera `172.17.x.x`:

```text
connect ADRES_WSL:27015
```

Aktualny adres WSL można sprawdzić wewnątrz WSL poleceniem:

```bash
hostname -I
```

Należy użyć pierwszego adresu, zwykle `172.x.x.x`. Adres może zmienić się po
restarcie WSL. Dla Dockera działającego bezpośrednio w WSL2 ruch UDP może nie
być przekazywany przez Windowsowy `localhost`, dlatego bezpośredni adres WSL
jest właściwym wyborem.

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
