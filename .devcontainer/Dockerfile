FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=ubuntu

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:${PATH} \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    GDK_BACKEND=x11 \
    NO_AT_BRIDGE=1 \
    LIBGL_ALWAYS_INDIRECT=1 \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/ccs-session-bus

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        dbus \
        dbus-x11 \
        default-mysql-client \
        default-libmysqlclient-dev \
        git \
        gir1.2-gtk-3.0 \
        gir1.2-gtksource-3.0 \
        gir1.2-notify-0.7 \
        gir1.2-vte-2.91 \
        libcairo2-dev \
        libgirepository1.0-dev \
        libgtk-3-dev \
        libnotify-dev \
        librsvg2-common \
        libvte-2.91-0 \
        pkg-config \
        procps \
        python3 \
        python3-cairo \
        python3-dbus \
        python3-dev \
        python3-gi \
        python3-gi-cairo \
        python3-pip \
        python3-venv \
        python-dbus-dev \
        sudo \
        x11-apps \
    && rm -rf /var/lib/apt/lists/* \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
    && python3 -m venv --system-site-packages "${VIRTUAL_ENV}" \
    && "${VIRTUAL_ENV}/bin/pip" install --upgrade pip setuptools wheel

COPY requirements.txt /tmp/ccs-requirements.txt

RUN "${VIRTUAL_ENV}/bin/pip" install -r /tmp/ccs-requirements.txt \
    && rm /tmp/ccs-requirements.txt \
    && mkdir -p /home/egse/OBSW \
    && chown -R "${USERNAME}:${USERNAME}" "${VIRTUAL_ENV}" /home/egse

COPY .devcontainer/start-container.sh /usr/local/bin/start-container
RUN chmod +x /usr/local/bin/start-container

USER ${USERNAME}
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/start-container"]
CMD ["sleep", "infinity"]
