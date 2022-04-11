FROM nestybox/ubuntu-bionic-systemd-docker:latest

ARG ssh_user
ENV env_ssh_user=$ssh_user

ARG ssh_user_pw
ENV env_ssh_user_pw=$ssh_user_pw

ARG ssh_root_pw
ENV env_ssh_root_pw=$ssh_root_pw



# Install nano, ping & docker-compose
RUN apt-get update \
    && apt install -y --no-install-recommends \
    nano \
    iputils-ping \
    docker-compose \
    git \
    jq \
    bash-completion \
    less \
    vim \
# Remove files necessary for installation, to cut the image size
    && rm -rf /var/lib/apt/lists/* \

# Config SSH-Server
RUN mkdir /var/run/sshd \
# Add user ssh_user
    && useradd --create-home --shell /bin/bash ${env_ssh_user} \
# Set password for user ssh_user
    && echo "${env_ssh_user}:${env_ssh_user_pw}" | chpasswd \
# Add user ssh_user to the sudo group
    && adduser ${env_ssh_user} sudo \
# Disables login via root user with ssh
    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin no/' /etc/ssh/sshd_config \
# Give the ssh_user user permissions to exec docker
    && usermod -aG docker ${env_ssh_user} \
# Change owing of /home/novatec to novatec user \
    && chown -R ${env_ssh_user} home/${env_ssh_user}/ \
# Activates login via ssh with username and password
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
# Set the timeout Interval of the ssh connection to 15min
    && sed -ri 's/#ClientAliveInterval 0/ClientAliveInterval 900/g' /etc/ssh/sshd_config \
# Create .kube dir for ssh_user user and add permission to access the Kubeconfig in there
    && mkdir -p home/${env_ssh_user}/.kube \
# Remove files necessary for installation, to cut the image size
    && rm -rf /var/lib/apt/lists/*


# Install curl & kubectl
RUN apt install -y --no-install-recommends curl \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && chmod +x kubectl \
    && mkdir -p ~/.local/bin/kubectl \
    && mv ./kubectl ~/.local/bin/kubectl \
    && kubectl version --client \
# Remove files necessary for installation, to cut the image size
    && rm -rf /var/lib/apt/lists/*


# Install wget & helm
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && wget https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz \
    && tar xvf helm-v3.4.1-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin \
    && rm helm-v3.4.1-linux-amd64.tar.gz \
    && rm -rf linux-amd64 \
    && helm version \
    && apt-get install -y --no-install-recommends tree \
# Remove files necessary for installation, to cut the image size
    && rm -rf /var/lib/apt/lists/* \

# Install k9s
RUN curl -sS https://webinstall.dev/k9s | bash \
    && export PATH="/root/.local/bin:$PATH" \

    # Install k9s for novatec user
    && su - novatec \
    && curl -sS https://webinstall.dev/k9s | bash \
    && export PATH="/home/novatec/.local/bin:$PATH"

# Remove files necessary for installation, to cut the image size
    && rm -rf /var/lib/apt/lists/*