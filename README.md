# ibmcloud-dev container image

Container image that contains common development tools for working with IBM Cloud. In particular this image
is used as the container in which CI pipelines run in order to complete common IBM Cloud and Kubernetes tasks.

`Cloud-Native Toolkit` images can be found on Quay: [ibmgaragecloud](https://quay.io/ibmgaragecloud)

Pull this container with the following Docker command:
```
docker pull quay.io/ibmgaragecloud/ibmcloud-dev
```

## Tools:

- build-essentials
- kubectl cli
- oc cli
- ibmcloud cli
- nvm
- node
- yq
- kustomize
- helm
- python
- tekton
- cloudnativetoolkit cli
