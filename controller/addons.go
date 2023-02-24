package controller

import (
	"fmt"

	"github.com/aws/aws-sdk-go/service/eks"
	eksv1 "github.com/rancher/eks-operator/pkg/apis/eks.cattle.io/v1"
	"github.com/sirupsen/logrus"
)

func (h *Handler) getClusterAddons(clusterName string, eksService *eks.EKS) ([]*eksv1.AddonState, error) {
	availableAddons, err := h.listAddons(clusterName, eksService)
	if err != nil {
		return nil, err
	}

	installed, err := h.getInstalledAddons(clusterName, availableAddons, eksService)
	if err != nil {
		return nil, err
	}

	return installed, nil
}

func (h *Handler) listAddons(clusterName string, eksService *eks.EKS) ([]*string, error) {
	logrus.Debugf("listing addons available for cluster %s", clusterName)

	input := &eks.ListAddonsInput{
		ClusterName: &clusterName,
	}

	output, err := eksService.ListAddons(input)
	if err != nil {
		return nil, fmt.Errorf("listing available addons for cluster %s: %w", clusterName, err)
	}

	return output.Addons, nil
}

func (h *Handler) getInstalledAddons(clusterName string, availableAddons []*string, eksService *eks.EKS) ([]*eksv1.AddonState, error) {
	logrus.Debugf("getting installed addons versions for cluster %s", clusterName)

	installed := []*eksv1.AddonState{}
	if len(availableAddons) == 0 {
		logrus.Infof("no eks addons available for cluster %s", clusterName)
		return installed, nil
	}

	for _, available := range availableAddons {
		input := &eks.DescribeAddonInput{
			AddonName:   available,
			ClusterName: &clusterName,
		}
		output, err := eksService.DescribeAddon(input)
		if err != nil {
			return installed, fmt.Errorf("describing addon %s for cluster %s: %w", *available, clusterName, err)
		}
		if output.Addon == nil {
			continue
		}
		installedAddon := &eksv1.AddonState{
			Name:                  *output.Addon.AddonName,
			Version:               *output.Addon.AddonVersion,
			ARN:                   *output.Addon.AddonArn,
			ServiceAccountRoleArn: output.Addon.ServiceAccountRoleArn,
			Status:                output.Addon.Status,
			Issues:                []eksv1.AddonIssue{},
		}
		//TODO: issues

		installed = append(installed, installedAddon)
	}

	return installed, nil
}
