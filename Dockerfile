FROM ubuntu:18.04

# Install some core libraries (build-essentials, sudo, python, curl)
RUN apt-get update -qq && \
    apt-get install -qq -y apt-transport-https && \
    apt-get install -qq -y gnupg gnupg2 gnupg1 && \
    apt-get install -qq -y build-essential && \
    apt-get install -qq -y sudo && \
    apt-get install -qq -y python && \
    apt-get install -qq -y curl && \
    apt-get install -qq -y software-properties-common uidmap
RUN add-apt-repository -y ppa:projectatomic/ppa && \
    apt-get update -qq && \
    apt-get -qq -y install podman buildah

RUN curl -O -L https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz &&\
    tar -zvxf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz &&\
    cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc /usr/local/bin &&\
    chmod +x /usr/local/bin/oc &&\
    rm -rf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit

# Configure sudoers so that sudo can be used without a password
RUN chmod u+w /etc/sudoers && echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create devops user
RUN groupadd -g 10000 devops && \
    useradd -u 10000 -g 10000 -G sudo,root -d /home/devops -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops

COPY src/.bashrc-ni /home/devops
COPY src/uid_entrypoint /usr/local/bin
RUN chown -R 10000:0 /home/devops && \
    chmod +x /usr/local/bin/uid_entrypoint && \
    chmod g=u /etc/passwd

USER 10000
WORKDIR /home/devops

# Install the ibmcloud cli
RUN curl -sL https://ibm.biz/idt-installer | bash && \
    ibmcloud config --check-version=false

# Add the devops user to the docker group
RUN sudo usermod -aG docker devops

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

RUN echo 'echo "Initializing environment..."' >> /home/devops/.bashrc-ni && \
    echo 'export NVM_DIR="${HOME}/.nvm"' >> /home/devops/.bashrc-ni && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/devops/.bashrc-ni

# Set the BASH_ENV to /home/devops/.bashrc-ni so that it is executed in a
# non-interactive shell
ENV BASH_ENV /home/devops/.bashrc-ni

# Pre-install node v11.12.0
RUN . /home/devops/.bashrc-ni && \
    nvm install v11.12.0 && \
    nvm use v11.12.0

RUN sudo apt-get install -y jq

RUN sudo chown -R 10000:0 /home/devops && \
    sudo chmod -R g=u /home/devops

RUN sudo apt-get autoremove && sudo apt-get clean

RUN opsys=linux; \
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest |\
    grep browser_download |\
    grep $opsys |\
    cut -d '"' -f 4 |\
    xargs curl -O -L &&\
    sudo mv kustomize_*_${opsys}_amd64 /usr/local/bin/kustomize &&\
    sudo chmod +x /usr/local/bin/kustomize

ENTRYPOINT [ "uid_entrypoint" ]
