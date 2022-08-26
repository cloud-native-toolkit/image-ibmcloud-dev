FROM centos:8 AS builder



#############################
# installing the Horizon CLI
############################

ENV HZN_CLI_VERSION 2.28.0-338
RUN curl -L -O https://github.com/open-horizon/anax/releases/download/v${HZN_CLI_VERSION}/horizon-agent-linux-rpm-x86_64.tar.gz && \
    tar xvf horizon-agent-linux-rpm-x86_64.tar.gz && \
    rpm -i horizon-cli*.rpm   
    
FROM docker.io/node:alpine3.12 


ENV TERRAFORM_IBMCLOUD_VERSION 1.9.0
ENV KUBECTL_VERSION 1.19.2
ENV OPENSHIFT_CLI_VERSION 4.5.11


RUN apk add --update-cache --update \
  curl \
  unzip \
  sudo \
  shadow \
  bash \
  openssl \
  alpine-sdk \
  python3 \
  skopeo \
  ca-certificates \
  && rm -rf /var/cache/apk/*

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

# Install IBM Cloud Terraform Provider
RUN mkdir -p ${HOME}/.terraform.d/plugins && \
    cd ${HOME}/.terraform.d/plugins && \
    curl -O -L https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v${TERRAFORM_IBMCLOUD_VERSION}/linux_amd64.zip &&\
    unzip linux_amd64.zip && \
    chmod +x terraform-provider-ibm_* &&\
    rm -rf linux_amd64.zip && \
    cd -

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

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash -s -- -v v3.4.2

RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod a+x jq-linux64 && \
    sudo mv jq-linux64 /usr/local/bin/jq

# install the IBM Garage Cloud Native Toolkit CLI
RUN sudo npm i -g @ibmgaragecloud/cloud-native-toolkit-cli

# Install the Tekton Pipelines CLI
RUN curl -LO https://github.com/tektoncd/cli/releases/download/v0.20.0/tkn_0.20.0_Linux_x86_64.tar.gz && \
    sudo tar xvzf tkn_0.20.0_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn && \
    rm tkn_0.20.0_Linux_x86_64.tar.gz

RUN wget -q -O ./yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    chmod +x ./yq && \
    sudo mv ./yq /usr/bin/yq

RUN GRPC_HEALTH_PROBE_VERSION=v0.4.6 && wget -qO ./grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && chmod +x ./grpc_health_probe && sudo mv ./grpc_health_probe /usr/bin/grpc_health_probe

COPY --from=builder /usr/bin/hzn /usr/bin/hzn   

ENTRYPOINT ["/bin/sh"]
