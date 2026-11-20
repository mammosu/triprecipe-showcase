# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.1
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# Ensure package installation runs as root (some devcontainer base images switch to a non-root user)
USER root

# ImageMagickとNoto Sans CJK JPフォントをインストール
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
  imagemagick \
  libmagickwand-dev \
  fonts-noto-cjk \
  fonts-noto-cjk-extra \
  nodejs \
  npm \
  python3-pip \
  git \
  direnv \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# フォントキャッシュを更新
RUN fc-cache -f -v

# ./bin/devをdevコマンドとして実行できるようにエイリアスを追加
RUN echo 'alias dev="/workspaces/triprecipe/bin/dev"' >> /home/vscode/.bashrc
RUN echo 'eval "$(direnv hook bash)"' >> /home/vscode/.bashrc

# uv (uvx) を vscodeユーザーでインストール
USER vscode
RUN curl -Ls https://astral.sh/uv/install.sh | bash
ENV PATH="/home/vscode/.cargo/bin:${PATH}"
# Switch back to the default non-root user used by the base image for the interactive dev session
USER vscode
