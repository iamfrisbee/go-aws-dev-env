FROM debian:bullseye-slim AS base

# env vars used for configuration
ENV GOPRIVATE="git-codecommit.*.amazonaws.com/v1/repos"
ENV GOPATH="/go"
ENV GOBIN="${GOPATH}/bin"
ENV NVM_DIR="/usr/local/share/nvm"
ENV PATH="/usr/local/go/bin:${NVM_DIR}:${PATH}"
ENV LANG=C
ENV LC_ALL="${LANG}"
ENV LANGUAGE="${LANG}"
ENV LC_CTYPE="${LANG}"

# directories needed
RUN mkdir /go
RUN mkdir /usr/local/share/nvm && chmod -R 0755 /usr/local/share && chmod 0777 ${NVM_DIR}

# update and install packages
RUN apt-get update \
  && apt-get install -y curl unzip git zsh zplug gcc vim sudo make locales gettext

FROM base AS installs

ARG TARGETARCH

RUN echo "build for ${TARGETARCH}"

# install golang
RUN curl -L "https://go.dev/dl/go1.20.linux-${TARGETARCH}.tar.gz" -o "go.tar.gz" \
  && rm -Rf /usr/local/go \
  && tar -C /usr/local -xzf go.tar.gz

RUN git clone https://github.com/go-delve/delve \
  && cd delve \
  && go install github.com/go-delve/delve/cmd/dlv

# install Go Language Server for IDEs
RUN go install golang.org/x/tools/gopls@latest

# install staticcheck for linting
RUN go install honnef.co/go/tools/cmd/staticcheck@v0.4.1

# install node js and serverless
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

# install aws cli
RUN cd /opt \
  && if [ "${TARGETARCH}" = "arm64" ]; then AWSARCH="aarch64"; else AWSARCH="x86_64"; fi \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWSARCH}.zip" -o "/opt/awscliv2.zip" \
  && unzip /opt/awscliv2.zip \
  && /opt/aws/install

FROM installs AS gouser
# create non-root user
RUN useradd -m -s /bin/zsh gouser -G sudo

# give user access to go
RUN chown -R gouser:gouser /go

# no password
RUN echo 'gouser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# install node for the user
RUN su gouser -c ". $NVM_DIR/nvm.sh && nvm install 18.15.0"

FROM gouser

RUN su gouser -c "mkdir ~/workspace"
RUN su gouser -c "mkdir ~/.ssh"

# copy configuration files
COPY ./.zshrc /home/gouser/.zshrc
COPY ./sshconfig.template /home/gouser/.ssh/sshconfig.template

# fix permissions
RUN chown -R gouser:gouser /home/gouser/.zshrc
RUN chown -R gouser:gouser /home/gouser/.ssh

# Makes go get use SSH instead of https for codecommit
RUN su gouser -c "git config --global url.\"ssh://git-codecommit.us-east-1.amazonaws.com\".insteadOf \"https://git-codecommit.us-east-1.amazonaws.com\""
RUN su gouser -c "git config --global url.\"ssh://git-codecommit.us-east-2.amazonaws.com\".insteadOf \"https://git-codecommit.us-east-2.amazonaws.com\""
RUN su gouser -c "git config --global url.\"ssh://git-codecommit.us-west-1.amazonaws.com\".insteadOf \"https://git-codecommit.us-west-1.amazonaws.com\""
RUN su gouser -c "git config --global url.\"ssh://git-codecommit.us-west-2.amazonaws.com\".insteadOf \"https://git-codecommit.us-west-2.amazonaws.com\""

# Safe directory
RUN su gouser -c "git config --global --add safe.directory /home/gouser/workspace"

# Set who's in charge
WORKDIR /home/gouser/workspace
USER gouser

# keep the lights on
CMD ["tail", "-f", "/dev/null"]
