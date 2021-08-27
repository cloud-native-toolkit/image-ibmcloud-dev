FROM centos:8



#############################
# installing the Horizon CLI
############################

COPY horizon-cli*.rpm /data/horizon-cli*.rpm
RUN rpm -i /data/horizon-cli*.rpm


ENV KUBECTL_VERSION 1.19.2
ENV OPENSHIFT_CLI_VERSION 4.5.11

RUN yum install -y \
  curl \
  unzip \
  sudo \
  bash \
  openssl \
  python3 \
  skopeo \
  wget \
  ca-certificates \
  && rm -rf /var/cache/rpm/*

WORKDIR $GOPATH/bin

##################################
# User setup
##################################

# Configure sudoers so that sudo can be used without a password
RUN groupadd --force sudo && \
    chmod u+w /etc/sudoers && \
    echo "%sudo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME /home/devops

# Create devops user
RUN useradd -u 10000 -g root -G sudo -d ${HOME} -m devops && \
    usermod --password $(echo password | openssl passwd -1 -stdin) devops && \
    chmod -R g+w ${HOME}

USER devops
WORKDIR ${HOME}

##################################
# IBM Cloud CLI
##################################

# Install the ibmcloud cli
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh && \
    ibmcloud plugin install container-service -f && \
    ibmcloud plugin install container-registry -f && \
    ibmcloud plugin install observe-service -f && \
    ibmcloud plugin install vpc-infrastructure -f && \
    ibmcloud config --check-version=false 


WORKDIR ${HOME}

RUN curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_CLI_VERSION}/openshift-client-linux.tar.gz --output oc-client.tar.gz && \
    mkdir tmp && \
    cd tmp && \
    tar xzf ../oc-client.tar.gz && \
    sudo mkdir -p /usr/local/fix && \
    sudo chmod a+rwx /usr/local/fix && \
    sudo cp ./oc /usr/local/fix && \
    sudo chmod +x /usr/local/fix/oc && \
    cd .. && \
    rm -rf tmp && \
    rm oc-client.tar.gz && \
    echo '/lib/ld-musl-x86_64.so.1 --library-path /lib /usr/local/fix/oc $@' > ./oc && \
    sudo mv ./oc /usr/local/bin && \
    sudo chmod +x /usr/local/bin/oc

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash && \
    chmod +x ./kustomize && \
    sudo mv ./kustomize /usr/local/bin

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod a+x jq-linux64 && \
    sudo mv jq-linux64 /usr/local/bin/jq

RUN wget -q -O ./yq $(wget -q -O - https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.assets[] | select(.name == "yq_linux_amd64") | .browser_download_url') && \
    chmod +x ./yq && \
    sudo mv ./yq /usr/bin/yq

ENTRYPOINT ["/bin/sh"]
