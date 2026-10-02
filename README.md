# Counter-Strike: Source 64-bit w Dockerze

Obraz instaluje SteamCMD, serwer CS:S, MetaMod:Source i SourceMod oraz pliki
potrzebne do uruchomienia serwera w trybie 64-bitowym. Po uruchomieniu kontenera
serwer startuje automatycznie.

## Budowanie

Pobieranie plików CS:S i TF2 odbywa się podczas budowania, dlatego pierwszy
build może potrwać kilka minut i wymaga kilku GB wolnego miejsca:

```bash
docker build -t css-server .
```

## Obraz z Docker Hub

Workflow `.github/workflows/docker-publish.yml` buduje i publikuje obraz przy
każdym pushu. Obraz ma nazwę `<użytkownik-dockerhub>/css-server`. Domyślna gałąź
dostaje tag `latest`; publikowane są też tagi odpowiadające gałęzi lub Git tagowi
oraz tag `sha-<skrót-commita>`.

W ustawieniach repozytorium GitHub w `Settings` > `Secrets and variables` >
`Actions` należy dodać dwa repository secrets:

- `DOCKERHUB_USERNAME` - nazwa użytkownika Docker Hub,
- `DOCKERHUB_TOKEN` - access token Docker Hub z uprawnieniami `Read & Write`.

Na Docker Hub należy wcześniej utworzyć repozytorium o nazwie `css-server`.
Gotowy obraz można pobrać bez lokalnego budowania:

```bash
docker pull <użytkownik-dockerhub>/css-server:latest
```

## Uruchomienie

Najprościej uruchomić serwer przez Docker Compose, który publikuje wszystkie
potrzebne porty:

```bash
docker compose up -d --build
docker compose logs -f
```

Compose ma również ustawione `pull_policy: build`, więc przy zwykłym
`docker compose up -d` sprawdzi build obrazu przed uruchomieniem kontenera.

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

Instalację pluginów można sprawdzić poleceniami `meta version` oraz
`sm version`.

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

## Konfiguracja zależna od mapy

Serwer używa pluginu
[Extended Map Configs](https://github.com/Nekromio/extendedmapconfig), kompilowanego
podczas budowania obrazu przez kompilator dołączony do SourceMod. Po każdej zmianie
mapy konfiguracje są wykonywane w kolejności:

1. `cfg/mapconfig/post/general/all.cfg`
2. `cfg/mapconfig/post/gametype/<prefiks>.cfg`
3. `cfg/mapconfig/post/maps/<pełna_nazwa_mapy>.cfg`

Prefiks jest częścią nazwy przed pierwszym znakiem `_`. Dlatego mapy `de_*` używają
`de.cfg`, `surf_*` używają `surf.cfg`, a `ba_jail_*` używają `ba.cfg`.

Wspólne ustawienia trybów znajdują się w `cfg/mapconfig/modes/`. Konfiguracja
`post/general/all.cfg` najpierw przywraca wartości z `base.cfg`, dzięki czemu np.
`sv_airaccelerate` z mapy bhop nie pozostaje aktywne na kolejnej mapie klasycznej.

Wyjątek dla pojedynczej mapy można dodać przykładowo jako:

```text
config/cfg/mapconfig/post/maps/surf_ski_2.cfg
```

Plugin automatycznie utworzy puste pliki dla map, które nie mają jeszcze własnej
konfiguracji. Konfiguracje wykonywane przed zmianą mapy znajdują się analogicznie
w `cfg/mapconfig/pre/`.

Osobne pule map są dostępne w plikach `mapcycle_classic.txt`,
`mapcycle_jailbreak.txt`, `mapcycle_surf.txt` i `mapcycle_bhop.txt`. Główne
głosowania nadal korzystają z mieszanego `mapcycle.txt`.

Pluginy wymagane tylko przez konkretny tryb należy trzymać poza głównym katalogiem
`addons/sourcemod/plugins` i ładować poleceniami `sm plugins load` w konfiguracji
trybu. Odpowiadające im `sm plugins unload` należy umieścić w
`cfg/mapconfig/pre/general/all.cfg`. Obecnie repo nie zawiera pluginów jailbreak,
surf ani bhop, więc nie są wykonywane puste operacje ładowania.

Niestandardowe mapy są pobierane podczas budowania z `main.fastdl.me`. Ten sam
serwis jest ustawiony w `server.cfg` jako `sv_downloadurl`, aby klient mógł pobrać
brakującą mapę przy łączeniu. Po zmianie adresu źródła map w `Dockerfile` należy
również zaktualizować adres FastDL w `server.cfg`.
