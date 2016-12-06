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
export KUBERNETES_PROVIDER="gce"
export E2E_MIN_STARTUP_PODS="8"
export KUBE_GCE_ZONE="us-central1-f"
export FAIL_ON_GCP_RESOURCE_LEAK="true"
export CLOUDSDK_CORE_PRINT_UNHANDLED_TRACEBACKS="1"

### project-env
# expected empty

### job-env
export KUBELET_TEST_ARGS="--experimental-cri=true"
export KUBE_FEATURE_GATES="StreamingProxyRedirects=true"

export E2E_NAME="e2e-scalability"
export GINKGO_TEST_ARGS="--ginkgo.focus=\[Feature:Performance\] \
                         --gather-resource-usage=true \
                         --gather-metrics-at-teardown=true \
                         --gather-logs-sizes=true \
                         --output-print-type=json"
# Create a project k8s-jenkins-scalability-head and move this test there
export PROJECT="k8s-jkns-cri-scalability"
export FAIL_ON_GCP_RESOURCE_LEAK="false"
# Override GCE defaults.
export MASTER_SIZE="n1-standard-4"
export NODE_SIZE="n1-standard-1"
export NODE_DISK_SIZE="50GB"
export NUM_NODES="100"
export ALLOWED_NOTREADY_NODES="1"
export REGISTER_MASTER="true"
# Reduce logs verbosity
export TEST_CLUSTER_LOG_LEVEL="--v=2"
# TODO(mtaufen): Remove kubelet log level bump when we solve issue #34911
export KUBELET_TEST_LOG_LEVEL="--v=5"
# Increase resync period to simulate production
export TEST_CLUSTER_RESYNC_PERIOD="--min-resync-period=12h"
# Increase delete collection parallelism
export TEST_CLUSTER_DELETE_COLLECTION_WORKERS="--delete-collection-workers=16"
export KUBE_NODE_OS_DISTRIBUTION="gci"

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
export DOCKER_TIMEOUT="140m"
export KUBEKINS_TIMEOUT="120m"
"${runner}"
