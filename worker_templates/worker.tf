resource "gzip_me" "ca" {
  input = "${ var.ca }"
}

resource "gzip_me" "worker" {
  input = "${ var.worker }"
}

resource "gzip_me" "worker_key" {
  input = "${ var.worker_key }"
}


resource "gzip_me" "kubelet_kubeconfig" {
  input = "${ data.template_file.kubelet_kubeconfig.rendered }"
}

data "template_file" "kubelet_kubeconfig" {
  template = "${ file( "${ path.module }/kubeconfig" )}"

  vars {
    cluster = "certificate-authority-data: ${ base64encode(var.ca) } \n    server: https://${ var.internal_lb_ip }"
    user = "kubelet"
    name = "service-account-context"
    user_authentication = "client-certificate-data: ${ base64encode(var.worker) } \n    client-key-data: ${ base64encode(var.worker_key) }"
  }
}





resource "gzip_me" "proxy_kubeconfig" {
  input = "${ data.template_file.proxy_kubeconfig.rendered }"
}

data "template_file" "proxy_kubeconfig" {
  template = "${ file( "${ path.module }/kubeconfig" )}"

  vars {
    cluster = "certificate-authority-data: ${ base64encode(var.ca) } \n    server: https://${ var.internal_lb_ip }"
    user = "kube-proxy"
    name = "service-account-context"
    user_authentication = "client-certificate-data: ${ base64encode(var.worker) } \n    client-key-data: ${ base64encode(var.worker_key) }"
  }
}





resource "gzip_me" "kube_proxy" {
  count = "${ var.worker_node_count}"
  input = "${ element(data.template_file.kube-proxy.*.rendered, count.index) }"
}

data "template_file" "kube-proxy" {
  count = "${ var.worker_node_count }"
  template = "${ file( "${ path.module }/kube-proxy.yml" )}"

  vars {
    master_node = "${ var.internal_lb_ip }"
    fqdn = "${ var.name }-worker${ count.index + 1 }"
    pod_cidr = "${ var.pod_cidr }"
    kube_proxy_registry = "${ var.kube_proxy_registry }"
    kube_proxy_tag = "${ var.kube_proxy_tag }"

  }
}





data "template_file" "worker_cloud_config" {
  count = "${ var.worker_node_count }"
  template = "${ file( "${ path.module }/worker-cloud-config.yml" )}"

  vars {
    cluster_domain = "${ var.cluster_domain }"
    cloud_provider = "${ var.cloud_provider }"
    cloud_config = "${ var.cloud_config }"
    cloud_config_file = "${ var.cloud_config_file }"
    dns_service_ip = "${ var.dns_service_ip }"
    non_masquerade_cidr = "${ var.non_masquerade_cidr }"
    ca = "${ gzip_me.ca.output }"
    worker = "${ gzip_me.worker.output }"
    worker_key = "${ gzip_me.worker_key.output }"
    proxy_kubeconfig = "${ gzip_me.proxy_kubeconfig.output }"
    kubelet_kubeconfig = "${ gzip_me.kubelet_kubeconfig.output }"
    kube_proxy = "${ element(gzip_me.kube_proxy.*.output, count.index) }"
    kubelet_artifact = "${ var.kubelet_artifact }"
    cni_artifact = "${ var.cni_artifact }"
    fqdn = "${ var.name }-worker${ count.index + 1 }"
  }
}