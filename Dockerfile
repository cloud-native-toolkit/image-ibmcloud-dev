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

RUN mkdir octmp &&\
    cd octmp &&\
    curl -O -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.5.11/openshift-client-linux.tar.gz &&\
    tar -zvxf openshift-client-linux.tar.gz &&\
    cp oc /usr/local/bin &&\
    chmod +x /usr/local/bin/oc &&\
    cd .. &&\
    rm -rf octmp

# Configure sudoers so that sudo can be used without a password
RUN chmod u+w /etc/sudoers && echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create devops user
RUN groupadd -g 1000 devops && \
    useradd -u 1000 -g 1000 -G sudo,root -d /home/devops -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops

COPY src/.bashrc-ni /home/devops
COPY src/uid_entrypoint /usr/local/bin
RUN chown -R 1000:0 /home/devops && \
    chmod +x /usr/local/bin/uid_entrypoint && \
    chmod g=u /etc/passwd

USER 1000
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
    nvm install v12 && \
    nvm use v12

RUN sudo apt-get install -y jq

RUN sudo chown -R 1000:0 /home/devops && \
    sudo chmod -R g=u /home/devops

RUN sudo add-apt-repository ppa:rmescandon/yq && \
    sudo apt-get update && \
    sudo apt-get install yq -y

RUN export arch=$(dpkg --print-architecture) && \
    export dist=bionic && \
    export version=2.26.12 && \
    curl -O http://pkg.bluehorizon.network/linux/ubuntu/pool/main/h/horizon/bluehorizon_${version}~ppa~ubuntu.${dist}_all.deb && \
    curl -O http://pkg.bluehorizon.network/linux/ubuntu/pool/main/h/horizon/horizon-cli_${version}~ppa~ubuntu.${dist}_${arch}.deb && \
    curl -O http://pkg.bluehorizon.network/linux/ubuntu/pool/main/h/horizon/horizon_${version}~ppa~ubuntu.${dist}_${arch}.deb && \
    sudo apt-get install -y systemd && \
    sudo dpkg -i horizon-cli_${version}~ppa~ubuntu.${dist}_${arch}.deb && \
    sudo dpkg -i horizon_${version}~ppa~ubuntu.${dist}_${arch}.deb && \
    sudo dpkg -i bluehorizon_${version}~ppa~ubuntu.${dist}_all.deb

RUN sudo apt-get autoremove && sudo apt-get clean

RUN opsys=linux && \
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases |\
      grep browser_download |\
      grep $opsys |\
      cut -d '"' -f 4 |\
      grep /kustomize/v |\
      sort | tail -n 1 |\
      xargs curl -O -L && \
    tar xzvf ./kustomize_v*_${opsys}_amd64.tar.gz && \
    sudo mv ./kustomize /usr/local/bin/kustomize && \
    sudo chmod +x /usr/local/bin/kustomize

RUN sudo chmod g+w /usr/local/share/ca-certificates && \
    sudo chmod g+w /usr/share/ca-certificates && \
    sudo chmod g+w /usr/local/share && \
    sudo chmod g+w /etc/ca-certificates.conf && \
    sudo chmod -R g+w /etc/ca-certificates && \
    sudo chmod -R g+w /etc/ssl/certs

RUN mkdir helm-tmp && \
    cd helm-tmp && \
    curl -L https://get.helm.sh/helm-v3.3.4-linux-amd64.tar.gz -o helm3.tar.gz && \
    tar xzf helm3.tar.gz && \
    sudo cp ./linux-amd64/helm /usr/local/bin && \
    cd .. && \
    rm -rf helm-tmp

ENV HOME /home/devops

ENTRYPOINT [ "uid_entrypoint" ]
