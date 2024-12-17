FROM mcr.microsoft.com/devcontainers/base:jammy

# Get this thing up-to-date
RUN apt-get update 
RUN apt-get upgrade -y

# Install some core tools
RUN apt-get install -y git curl inotify-tools wget imagemagick

# Erlang Deps
RUN apt-get install -y build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

# Install ASDF
RUN git clone https://github.com/asdf-vm/asdf.git /opt/asdf --branch v0.13.1

# install Elixir and Erlang
ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.1.2
RUN sh -c 'echo "source /opt/asdf/asdf.sh" >> /home/vscode/.bashrc'
RUN sudo -u vscode bash -c 'source /opt/asdf/asdf.sh && asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git'
RUN sudo -u vscode bash -c "source /opt/asdf/asdf.sh && asdf install erlang $ERLANG_VERSION && asdf global erlang $ERLANG_VERSION"
RUN sudo -u vscode bash -c 'source /opt/asdf/asdf.sh && asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git'
RUN sudo -u vscode bash -c "source /opt/asdf/asdf.sh && asdf install elixir $ELIXIR_VERSION && asdf global elixir $ELIXIR_VERSION"

# install NodeJS and Yarn
ARG NODEJS_VERSION=20.15.0
RUN sudo -u vscode bash -c 'source /opt/asdf/asdf.sh && asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git'
RUN sudo -u vscode bash -c "source /opt/asdf/asdf.sh && asdf install nodejs $NODEJS_VERSION && asdf global nodejs $NODEJS_VERSION"
RUN sudo -u vscode bash -c 'source /opt/asdf/asdf.sh && npm install --global yarn'

# locale
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US:en

CMD ["/bin/bash"]