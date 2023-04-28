#!/bin/bash
#
# Submit new EKS operator version against rancher/charts

set -ue

PREV_EKS_OPERATOR_VERSION="$1"   # e.g. 1.1.0-rc3
NEW_EKS_OPERATOR_VERSION="$2"
PREV_CHART_VERSION="$3"   # e.g. 101.2.0
NEW_CHART_VERSION="$4"
REPLACE="$5"              # remove previous version if `true`, otherwise add new

if [ -z "${GITHUB_WORKSPACE:-}" ]; then
    CHARTS_DIR="$(dirname -- "$0")/../../../charts"
else
    CHARTS_DIR="${GITHUB_WORKSPACE}/charts"
fi

pushd "${CHARTS_DIR}" > /dev/null

if [ ! -e ~/.gitconfig ]; then
    git config --global user.name "highlander-ci-bot"
    git config --global user.email highlander-ci@proton.me
fi

if [ ! -f bin/charts-build-scripts ]; then
    make pull-scripts
fi

find ./packages/rancher-eks-operator/ -type f -exec sed -i -e "s/${PREV_EKS_OPERATOR_VERSION}/${NEW_EKS_OPERATOR_VERSION}/g" {} \;
find ./packages/rancher-eks-operator/ -type f -exec sed -i -e "s/version: ${PREV_CHART_VERSION}/version: ${NEW_CHART_VERSION}/g" {} \;

if [ "${REPLACE}" == "true" ]; then
    sed -i -e "s/${PREV_CHART_VERSION}+up${PREV_EKS_OPERATOR_VERSION}/${NEW_CHART_VERSION}+up${NEW_EKS_OPERATOR_VERSION}/g" release.yaml
else
    sed -i -e "s/${PREV_CHART_VERSION}+up${PREV_EKS_OPERATOR_VERSION}/${PREV_CHART_VERSION}+up${PREV_EKS_OPERATOR_VERSION}\n${NEW_CHART_VERSION}+up${NEW_EKS_OPERATOR_VERSION}/g" release.yaml
    if grep -qv "rancher-eks-operator:" release.yaml; then

        cat <<< "rancher-eks-operator:
- ${PREV_CHART_VERSION}+up${PREV_EKS_OPERATOR_VERSION}
- ${NEW_CHART_VERSION}+up${NEW_EKS_OPERATOR_VERSION}
rancher-eks-operator-crd:
- ${PREV_CHART_VERSION}+up${PREV_EKS_OPERATOR_VERSION}
- ${NEW_CHART_VERSION}+up${NEW_EKS_OPERATOR_VERSION}" >> release.yaml

    fi
fi

git add packages/rancher-eks-operator release.yaml
git commit -m "Updating to EKS Operator v${NEW_EKS_OPERATOR_VERSION}"

if [ "${REPLACE}" == "true" ]; then
for i in rancher-eks-operator rancher-eks-operator-crd; do CHART=$i VERSION=${PREV_CHART_VERSION}+up${PREV_EKS_OPERATOR_VERSION} make remove; done
fi

PACKAGE=rancher-eks-operator make charts
git add assets/rancher-eks-operator* charts/rancher-eks-operator* index.yaml
git commit -m "Autogenerated changes for EKS Operator v${NEW_EKS_OPERATOR_VERSION}"

popd > /dev/null
