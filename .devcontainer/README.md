# Ubuntu 24.04 GTK dev container on macOS

This setup implements the Ubuntu installation in `README_CoCa.md`. The app
container includes Python 3.12, GTK 3, GtkSourceView 3, VTE, Notify, Cairo,
D-Bus development files, GdkPixbuf SVG support, MySQL client/development files, the project
requirements, and a system-site-enabled virtual environment at `/opt/venv`.
It works on both Intel and Apple Silicon Macs through Docker Desktop's matching
Ubuntu image architecture.

A private MySQL 8.4 service is included. It creates the `ccs` user and
`mib_schema_coca` schema using the values already present in `egse.cfg`. The app
shares its network namespace, so the guide's `host = 127.0.0.1` remains valid.
Database contents persist in the Compose volume `ccs-mysql-data`.

## Configure local database credentials

Create the ignored environment file before opening the dev container:

```sh
cp .devcontainer/.env.example .devcontainer/.env
chmod 600 .devcontainer/.env
```

Replace the two example passwords in `.devcontainer/.env`. Compose passes the
regular MySQL password to the post-create installer, which writes it into a
private runtime copy of `egse.cfg` under `/home/ubuntu/.config/ccs/`. The
installed `confignator` package reads that runtime copy; no database password
or environment-specific lookup is stored in application source code or tracked
configuration. Keep `MYSQL_USER=ccs` and
`MYSQL_DATABASE=mib_schema_coca` unless you also update `egse.cfg`.

MySQL initialization variables are only applied when its data volume is first
created. To change the password after initialization, update it inside MySQL or
recreate the development database volume. Recreating the volume permanently
deletes its schemas and data.

The configuration follows the standard Dev Container specification and works
with both PyCharm and Visual Studio Code. Linux GUI windows need an X server on
macOS, regardless of which IDE is used. Install and configure XQuartz once:

1. Install [XQuartz](https://www.xquartz.org/) (`brew install --cask xquartz`
   is also fine), then log out of macOS and back in if this is a new install.
2. In **XQuartz > Settings > Security**, enable **Allow connections from
   network clients**, then completely quit XQuartz.
3. In a macOS terminal, enable its TCP listener and fully restart its
   processes:

   ```sh
   defaults write org.xquartz.X11 nolisten_tcp -bool false
   killall XQuartz 2>/dev/null
   killall X11.bin 2>/dev/null
   open -a XQuartz
   ```

4. Authorize local Docker Desktop connections:

   ```sh
   /opt/X11/bin/xhost +localhost
   ```

   Run that command again after XQuartz is restarted. Do not use the much less
   restrictive `xhost +`.

You can confirm that display 0 is listening before opening the container:

```sh
defaults read org.xquartz.X11 nolisten_tcp
lsof -nP -iTCP:6000 -sTCP:LISTEN
```

The first command must print `0`, and `lsof` should show `X11.bin` listening
on port 6000. If the preference is `0` but no listener appears, log out of
macOS and back in (or reboot), then start XQuartz again.

## Open the dev container

### PyCharm

With Docker Desktop and XQuartz running, open this repository in PyCharm and
choose **Dev Containers > Create Dev Container and Mount Sources** from the
project's context menu. Select `.devcontainer/devcontainer.json` if prompted.

Use `/opt/venv/bin/python` as the interpreter. Recent PyCharm versions normally
detect it automatically because it is first on `PATH`. If your PyCharm edition
does not offer Dev Containers, add a **Docker Compose** Python interpreter
instead, select `.devcontainer/compose.yaml`, service `app`, and interpreter
path `/opt/venv/bin/python`.

### Visual Studio Code

1. Install Docker Desktop and the Microsoft **Dev Containers** extension in
   VS Code.
2. Open this repository in VS Code.
3. Open the Command Palette and select **Dev Containers: Reopen in
   Container**.

VS Code reads `.devcontainer/devcontainer.json`, starts both the app and MySQL
services, installs its Python extension in the container, and selects
`/opt/venv/bin/python`. If prompted to choose an interpreter manually, run
**Python: Select Interpreter** and enter that path.

On first creation, `.devcontainer/post-create.sh` follows the CoCa guide by
running `make confignator`, `make databases`, importing the real CoCa SCOS MIB,
and performing a GTK/D-Bus import check. The CoCa MIB working-tree directory
was removed from this branch, so the installer extracts the original dataset
from its repository commit `67bc00c` into a temporary directory before import.

## Verify GUI forwarding

From the IDE terminal inside the container, run:

```sh
python .devcontainer/gtk_smoke_test.py
```

A small window should appear on the Mac desktop. You can then run the project,
for example with `./start_ccs` or `python Ccs/ccs.py`.

## Launch the CoCa interfaces

Run these commands in a terminal connected to the dev container, with
`/workspace` as the current directory.

Start the main CoCa-configured CCS Editor:

```sh
./start_ccs
```

If an existing container reports that `mib_schema_coca.pic` does not exist,
run the real CoCa MIB importer once and retry:

```sh
bash .devcontainer/import-coca-mib.sh
./start_ccs
```

The message `No module named 'calibrations_COMETINTERCEPTOR'` is a non-fatal
warning: CCS falls back to no project-specific external calibration. A real
calibration module should be supplied if the CoCa definition requires one.

Start the Test Specification Tool in a second container terminal:

```sh
./start_tst
```

The windows are Linux GTK applications and appear on the macOS desktop through
XQuartz rather than inside the IDE window. Keep XQuartz running. If it was
restarted, run `/opt/X11/bin/xhost +localhost` again on the Mac before launching
the interfaces.

For a PyCharm Run Configuration for the main UI, use:

- **Python interpreter:** `/opt/venv/bin/python`
- **Script path:** `/workspace/Ccs/ccs.py`
- **Working directory:** `/workspace`
- **Environment:** `DISPLAY=host.docker.internal:0`

For VS Code, launching `./start_ccs` from the integrated container terminal is
sufficient. A `launch.json` configuration can use the same interpreter, script,
working directory, and `DISPLAY` value shown above.

## Remaining CoCa-specific inputs

The repository currently has `obsw = /home/egse/OBSW` in `egse.cfg`. That
directory is created in the container, but you must populate it or change the
path if the OBSW sources live elsewhere.

The CoCa SCOS2000 MIB exports referenced by `README_CoCa.md` were removed from
the current working tree, but remain in this branch's Git history. The
post-create installer extracts and imports that exact dataset automatically.
To run the installation explicitly, use:

```sh
bash .devcontainer/import-coca-mib.sh
```

The helper leaves an already populated MIB unchanged. To deliberately replace
an existing MIB, invoke `Ccs/tools/import_mib.py` directly as documented in
`README_CoCa.md`; that importer drops and recreates the selected schema.

If the test reports `cannot open display`, confirm all three of these are true:
XQuartz is running, network clients are enabled, and `xhost +localhost` was run
after the latest XQuartz start. The container is already configured with
`DISPLAY=host.docker.internal:0` and uses X11 rather than Wayland.
