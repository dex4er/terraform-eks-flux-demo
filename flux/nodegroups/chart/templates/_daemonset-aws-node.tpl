{{- define "daemonset.aws-node" }}
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app.kubernetes.io/instance: aws-vpc-cni
    app.kubernetes.io/name: aws-node
    app.kubernetes.io/version: v1.15.1
    k8s-app: aws-node-{{ .nodegroup }}
  name: aws-node-{{ .nodegroup }}
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: aws-node-{{ .nodegroup }}
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: aws-vpc-cni
        app.kubernetes.io/name: aws-node
        k8s-app: aws-node-{{ .nodegroup }}
    spec:
      nodeSelector:
        nodegroup/{{ .nodegroup }}: "true"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64
                - arm64
              - key: eks.amazonaws.com/compute-type
                operator: NotIn
                values:
                - fargate
      containers:
      - env:
        - name: ENABLE_PREFIX_DELEGATION
          value: "true"
        - name: WARM_IP_TARGET
          value: "0"
        - name: MINIMUM_IP_TARGET
          value: "{{ .maxPods }}"
        - name: AWS_VPC_K8S_CNI_LOGLEVEL
          value: info
        - name: AWS_VPC_K8S_CNI_LOG_FILE
          value: stderr
        - name: AWS_VPC_K8S_PLUGIN_LOG_LEVEL
          value: info
        - name: AWS_VPC_K8S_PLUGIN_LOG_FILE
          value: stderr
        - name: ADDITIONAL_ENI_TAGS
          value: '{}'
        - name: AWS_VPC_CNI_NODE_PORT_SUPPORT
          value: "true"
        - name: AWS_VPC_ENI_MTU
          value: "9001"
        - name: AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG
          value: "false"
        - name: AWS_VPC_K8S_CNI_EXTERNALSNAT
          value: "false"
        - name: AWS_VPC_K8S_CNI_RANDOMIZESNAT
          value: prng
        - name: AWS_VPC_K8S_CNI_VETHPREFIX
          value: eni
        - name: DISABLE_INTROSPECTION
          value: "false"
        - name: DISABLE_METRICS
          value: "false"
        - name: DISABLE_NETWORK_RESOURCE_PROVISIONING
          value: "false"
        - name: ENABLE_IPv4
          value: "true"
        - name: ENABLE_IPv6
          value: "false"
        - name: ENABLE_POD_ENI
          value: "false"
        - name: VPC_CNI_VERSION
          value: v1.15.1
        - name: WARM_ENI_TARGET
          value: "1"
        - name: WARM_PREFIX_TARGET
          value: "1"
        - name: MY_NODE_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: spec.nodeName
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        image: 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni:v1.15.1
        livenessProbe:
          exec:
            command:
            - /app/grpc-health-probe
            - -addr=:50051
            - -connect-timeout=5s
            - -rpc-timeout=5s
          initialDelaySeconds: 60
          timeoutSeconds: 20
        name: aws-node
        ports:
        - containerPort: 61678
          name: metrics
        readinessProbe:
          exec:
            command:
            - /app/grpc-health-probe
            - -addr=:50051
            - -connect-timeout=5s
            - -rpc-timeout=5s
          initialDelaySeconds: 1
          timeoutSeconds: 10
        resources:
          limits:
            memory: 256Mi
          requests:
            cpu: 100m
            memory: 256Mi
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
            - NET_RAW
        volumeMounts:
        - mountPath: /host/opt/cni/bin
          name: cni-bin-dir
        - mountPath: /host/etc/cni/net.d
          name: cni-net-dir
        - mountPath: /host/var/log/aws-routed-eni
          name: log-dir
        - mountPath: /var/run/aws-node
          name: run-dir
        - mountPath: /run/xtables.lock
          name: xtables-lock
      - args:
        - --enable-ipv6=false
        - --enable-network-policy=false
        - --enable-cloudwatch-logs=false
        - --enable-policy-event-logs=false
        - --metrics-bind-addr=:8162
        - --health-probe-bind-addr=:8163
        env:
        - name: MY_NODE_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: spec.nodeName
        image: 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-network-policy-agent:v1.0.4
        name: aws-eks-nodeagent
        resources:
          limits:
            memory: 256Mi
          requests:
            cpu: 100m
            memory: 256Mi
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
          privileged: true
        volumeMounts:
        - mountPath: /host/opt/cni/bin
          name: cni-bin-dir
        - mountPath: /sys/fs/bpf
          name: bpf-pin-path
        - mountPath: /var/log/aws-routed-eni
          name: log-dir
        - mountPath: /var/run/aws-node
          name: run-dir
      hostNetwork: true
      initContainers:
      - env:
        - name: DISABLE_TCP_EARLY_DEMUX
          value: "false"
        - name: ENABLE_IPv6
          value: "false"
        image: 602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni-init:v1.15.1
        name: aws-vpc-cni-init
        resources:
          requests:
            cpu: 25m
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /host/opt/cni/bin
          name: cni-bin-dir
      priorityClassName: system-node-critical
      securityContext: {}
      serviceAccountName: aws-node
      terminationGracePeriodSeconds: 10
      tolerations:
      - operator: Exists
      volumes:
      - hostPath:
          path: /sys/fs/bpf
        name: bpf-pin-path
      - hostPath:
          path: /opt/cni/bin
        name: cni-bin-dir
      - hostPath:
          path: /etc/cni/net.d
        name: cni-net-dir
      - hostPath:
          path: /var/log/aws-routed-eni
          type: DirectoryOrCreate
        name: log-dir
      - hostPath:
          path: /var/run/aws-node
          type: DirectoryOrCreate
        name: run-dir
      - hostPath:
          path: /run/xtables.lock
        name: xtables-lock
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 25%
    type: RollingUpdate
{{- end }}
