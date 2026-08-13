FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG UBUNTU_CODENAME=noble

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update -y \
  && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    gpg \
    sudo \
    wget \
  && wget -O- https://apt.kitware.com/keys/kitware-archive-latest.asc \
    | gpg --dearmor \
    | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
  && echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${UBUNTU_CODENAME} main" \
    > /etc/apt/sources.list.d/kitware.list \
  && apt-get update -y \
  && apt-get install --no-install-recommends -y kitware-archive-keyring \
  && apt-get update -y \
  && apt-get install --no-install-recommends -y \
    ccache \
    clang \
    clangd \
    cmake \
    cpio \
    dpkg-dev \
    file \
    g++ \
    gdb \
    git \
    less \
    libarchive-dev \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libxml2-utils \
    libxslt1-dev \
    make \
    man \
    nano \
    ninja-build \
    openjdk-17-jdk-headless \
    pkg-config \
    python3 \
    ripgrep \
    tree \
    valgrind \
    vim \
    zip \
  && rm -rf /var/lib/apt/lists/*

RUN if getent group "${USER_GID}" >/dev/null; then \
      GROUP_NAME="$(getent group "${USER_GID}" | cut -d: -f1)"; \
    else \
      GROUP_NAME="${USERNAME}"; \
      groupadd --gid "${USER_GID}" "${GROUP_NAME}"; \
    fi \
  && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}" \
  && usermod -aG sudo "${USERNAME}" \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
  && chmod 0440 "/etc/sudoers.d/${USERNAME}"

ENV CC=clang
ENV CXX=clang++
ENV PATH="/workspace/srcML-install/bin:/workspace/srcDiff/build/bin:/workspace/srcReader/build/bin:/workspace/srcMove/build:${PATH}"

WORKDIR /workspace
USER ${USERNAME}

CMD ["/bin/bash"]
