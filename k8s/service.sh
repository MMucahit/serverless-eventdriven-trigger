Minikube Commands: minikube status
  minikube ssh
  minikube ip
  minikube image load {image_name:version}

Kubectl Commands: kubectl get deploy -n {namespace_name}
  kubectl get pods -n {namespace_name}
  kubectl get services -n {namespace_name}

  kubectl get sensor -n {namespace_name}
  kubectl get eventsource -n {namespace_name}

  kubectl get sensor -n {namespace} {sensor_name} -o yaml
  kubectl get eventsource -n {namespace} {eventsource_name} -o yaml

  kubectl get clusterroles
  kubectl get clusterrolebindings

  kubectl get roles -n {namespace_name}
  kubectl get rolebindings -n {namespace_name}

  kubectl get role {role_name} -n {namespace_name} -o yaml

  kubectl logs -f {pod_name} -n {namespace_name}

  Container lifetime:
    kubectl get pods -n argo-events -o json | jq -r '
    .items[] |
    {
    name: .metadata.name,
    startedAt: (.status.containerStatuses[0].state.terminated.startedAt // "N/A"),
    finishedAt: (.status.containerStatuses[0].state.terminated.finishedAt // "N/A")
    } |
    "\(.name)\t\(.startedAt)\t\(.finishedAt)"'

  Pod lifetime:
    kubectl get pods -n argo-events -o json | jq -r '
    .items[] |
    select(.status.containerStatuses[0].state.terminated != null) |
    {
    name: .metadata.name,
    created: .metadata.creationTimestamp,
    finished: .status.containerStatuses[0].state.terminated.finishedAt
    } |
    "\(.name)\t\(.created)\t\(.finished)"' | while IFS=$'\t' read -r name created finished; do
          created_epoch=$(date -d "$created" +%s)
          finished_epoch=$(date -d "$finished" +%s)
          duration=$((finished_epoch - created_epoch))
    echo -e "$name\t$duration saniye (pod ömrü)"
    done

Create Namespace: kubectl create namespace argo-events

Install argo-events and eventbus: kubectl apply \
  --filename https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml

  kubectl --namespace argo-events apply \
  --filename https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml

Apply Redis: kubectl apply -f redis-deployment.yaml -n argo-events
  kubectl apply -f redis-service.yaml -n argo-events

Connect Redis: kubectl exec -it {pod_name} -n {namespace_name} -- sh

Read Redis log: redis-cli --csv psubscribe '**keyevent@0**:expired'

Apply Eventsource: cd k8s, kubectl apply -f eventsource/redis-eventsource.yaml -n argo-events
Apply Sensor: cd k8s, kubectl apply -f sensor/redis-sensor.yaml -n argo-events
