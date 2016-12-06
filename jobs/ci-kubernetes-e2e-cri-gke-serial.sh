#!/bin/bash
# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

readonly testinfra="$(dirname "${0}")/.."

### provider-env
export CLOUDSDK_API_ENDPOINT_OVERRIDES_CONTAINER="https://test-container.sandbox.googleapis.com/"
export CLOUDSDK_BUCKET="gs://cloud-sdk-testing/ci/staging"
export E2E_MIN_STARTUP_PODS="8"
export FAIL_ON_GCP_RESOURCE_LEAK="true"
export KUBERNETES_PROVIDER="gke"
export ZONE="us-central1-f"

### project-env
# expected empty

### job-env
export KUBELET_TEST_ARGS="--experimental-cri=true"
export KUBE_FEATURE_GATES="StreamingProxyRedirects=true"

export ENABLE_GARBAGE_COLLECTOR="true"
export CLOUDSDK_CONTAINER_USE_CLIENT_CERTIFICATE=False
export GINKGO_TEST_ARGS="--ginkgo.focus=\[Serial\]|\[Disruptive\] \
                         --ginkgo.skip=\[Flaky\]|\[Feature:.+\]"
export PROJECT="k8s-jkns-gke-cri-e2e-serial"
export KUBE_GKE_IMAGE_TYPE="gci"

### post-env

# Assume we're upping, testing, and downing a cluster
export E2E_UP="${E2E_UP:-true}"
export E2E_TEST="${E2E_TEST:-true}"
export E2E_DOWN="${E2E_DOWN:-true}"

export E2E_NAME='bootstrap-e2e'

# Skip gcloud update checking
export CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=true
# Use default component update behavior
export CLOUDSDK_EXPERIMENTAL_FAST_COMPONENT_UPDATE=false

# AWS variables
export KUBE_AWS_INSTANCE_PREFIX="${E2E_NAME}"

# GCE variables
export INSTANCE_PREFIX="${E2E_NAME}"
export KUBE_GCE_NETWORK="${E2E_NAME}"
export KUBE_GCE_INSTANCE_PREFIX="${E2E_NAME}"

# GKE variables
export CLUSTER_NAME="${E2E_NAME}"
export KUBE_GKE_NETWORK="${E2E_NAME}"

# Get golang into our PATH so we can run e2e.go
export PATH="${PATH}:/usr/local/go/bin"

### Runner
readonly runner="${testinfra}/jenkins/dockerized-e2e-runner.sh"
export DOCKER_TIMEOUT="320m"
export KUBEKINS_TIMEOUT="300m"
"${runner}"
