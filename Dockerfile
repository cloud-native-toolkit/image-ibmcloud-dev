FROM docker.io/node:alpine3.12

ENV TERRAFORM_IBMCLOUD_VERSION 1.9.0
ENV KUBECTL_VERSION 1.19.2
ENV OPENSHIFT_CLI_VERSION 4.5.11
ENV HOST_TYPE linux-rpm-x86_64 

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
  && rm -rf /var/cache/apk/* \
  && apk add  /hzn-cli-packages/horizon-cli-2.28.0-338.x86_64.rpm
#  && ./horizon-cli*.rpm ./horizon-cli*.rpm
ENV  HZN_ORG_ID dow
ENV HZN_EXCHANGE_USER_AUTH iamapikey:OoTK8lmkYNFix7NY8LhtnLKl0KK2g0JF_tlC_ztWB8mh
ENV HZN_EXCHANGE_URL https://cp-console.dow-mvp-0063h00000ekgoj-afb9c6047b062b44e3f1b3ecfeba4309-0000.us-south.containers.appdomain.cloud/edge-exchange/v1
ENV HZN_FSS_CSSURL https://cp-console.dow-mvp-0063h00000ekgoj-afb9c6047b062b44e3f1b3ecfeba4309-0000.us-south.containers.appdomain.cloud/edge-css/
ENV AGENT_NAMESPACE openhorizon-agent


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

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod a+x jq-linux64 && \
    sudo mv jq-linux64 /usr/local/bin/jq

RUN wget -q -O ./yq $(wget -q -O - https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.assets[] | select(.name == "yq_linux_amd64") | .browser_download_url') && \
    chmod +x ./yq && \
    sudo mv ./yq /usr/bin/yq

ENTRYPOINT ["/bin/sh"]
