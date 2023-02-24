module github.com/rancher/eks-operator

go 1.16

replace k8s.io/client-go => k8s.io/client-go v0.25.4

require (
	github.com/aws/aws-sdk-go v1.44.83
	github.com/blang/semver v3.5.1+incompatible
	github.com/google/go-cmp v0.5.9 // indirect
	github.com/rancher/lasso v0.0.0-20221202205459-e7138f16489c
	github.com/rancher/wrangler v1.0.2
	github.com/rancher/wrangler-api v0.6.1-0.20200427172631-a7c2f09b783e
	github.com/sirupsen/logrus v1.8.1
	github.com/stretchr/testify v1.8.0
	k8s.io/api v0.25.4
	k8s.io/apimachinery v0.25.4
	k8s.io/client-go v12.0.0+incompatible
)
