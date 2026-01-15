resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in local.nodes : v.mgmt_ip]
  endpoints            = [for k, v in local.nodes : v.mgmt_ip if v.machine_type == "controlplane"]
}

data "talos_machine_configuration" "this" {
  for_each     = local.nodes
  cluster_name = var.cluster_name
  # This is the Kubernetes API Server endpoint.
  # ref - https://www.talos.dev/latest/introduction/prodnotes/#decide-the-kubernetes-endpoint
  cluster_endpoint = local.cluster_endpoint
  talos_version    = var.talos_version
  machine_type     = each.value.machine_type
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "this" {
  depends_on                  = [module.talos_vm]
  for_each                    = local.nodes
  node                        = each.value.mgmt_ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  config_patches = [
    templatefile("${local.talos_templates_path}/common.yaml.tpl", {
      machine_type     = each.value.machine_type
      node_labels      = each.value.labels != null ? jsonencode(each.value.labels) : null
      hostname         = each.value.hostname
      nameservers      = jsonencode(var.nameservers)
      pod_subnet_cidrs = jsonencode(var.pod_subnet_cidrs)
      svc_subnet_cidrs = jsonencode(var.svc_subnet_cidrs)
      mgmt_address     = each.value.mgmt_address
      mgmt_gateway_ip  = var.mgmt_gateway_ip
      mgmt_mac         = macaddress.mgmt[each.key].address
      mgmt_mtu         = var.mgmt_mtu
      ceph_address     = each.value.ceph_address
      ceph_mac         = macaddress.ceph[each.key].address
      ceph_mtu         = var.ceph_mtu

      allow_scheduling_on_control_planes = var.allow_scheduling_on_control_planes
    }),
    each.value.machine_type == "controlplane" ? templatefile("${local.talos_templates_path}/control-plane.yaml.tpl", {
      mgmt_mac       = macaddress.mgmt[each.key].address
      vip_ip         = var.mgmt_vip_ip
      calico_version = var.calico_version
    }) : null
    # each.value.machine_type == "controlplane" ? templatefile("${local.talos_patches_path}/controllers/vip.yaml.tpl", {
    #   vip = var.mgmt_vip_ip
    # }) : null
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.this]
  node                 = local.bootstrap_node
  client_configuration = talos_machine_secrets.this.client_configuration
}

# # save the talos client configuration locally so we can apply the multi-file talos patches
# resource "local_file" "talos_configuration" {
#   depends_on = [talos_machine_configuration_apply.this]
#   content    = talos_machine_secrets.this.client_configuration.content
#   filename   = "${path.module}/../_out/talosconfig"
# }

# resource "local_file" "mgmt_link_alias_config" {
#   depends_on = [local_file.talos_configuration]
#   for_each   = local.nodes
#   filename   = "${path.module}/../generated/node-${each.key}/mgmt_link_alias_config.json"
#   content = jsonencode({
#     apiVersion : "v1alpha1"
#     kind : "LinkAliasConfig"
#     name : "mgmt"
#     selector : {
#       match : "${macaddress.mgmt[each.key].address} == mac(link.permanent_addr)"
#     }
#   })
# }

# resource "local_file" "mgmt_link_config" {
#   depends_on = [local_file.talos_configuration]
#   for_each   = local.nodes
#   filename   = "${path.module}/../generated/node-${each.key}/mgmt_link_config.json"
#   content = jsonencode({
#     apiVersion : "v1alpha1"
#     kind : "LinkConfig"
#     name : "mgmt"
#     up : true
#     mtu : var.mgmt_mtu
#     addresses : [
#       { address : each.value.mgmt_address }
#     ],
#     routes : [
#       {
#         destination : "default"
#         gateway : var.mgmt_gateway_ip
#       }
#     ]
#   })
# }

# resource "local_file" "ceph_link_alias_config" {
#   depends_on = [local_file.talos_configuration]
#   for_each   = local.nodes
#   filename   = "${path.module}/../generated/node-${each.key}/ceph_link_alias_config.json"
#   content = jsonencode({
#     apiVersion : "v1alpha1"
#     kind : "LinkAliasConfig"
#     name : "ceph"
#     selector : {
#       match : "${macaddress.ceph[each.key].address} == mac(link.permanent_addr)"
#     }
#   })
# }

# resource "local_file" "ceph_link_config" {
#   depends_on = [local_file.talos_configuration]
#   for_each   = local.nodes
#   filename   = "${path.module}/../generated/node-${each.key}/ceph_link_config.json"
#   content = jsonencode({
#     apiVersion : "v1alpha1"
#     kind : "LinkConfig"
#     name : "ceph"
#     up : true
#     mtu : var.ceph_mtu
#     addresses : [
#       { address : each.value.ceph_address }
#     ]
#   })
# }

# resource "local_file" "controlplane_vip" {
#   depends_on = [local_file.talos_configuration]
#   filename   = "${path.module}/../generated/controlplane/vip.json"
#   content = jsonencode({
#     apiVersion : "v1alpha1"
#     kind : "Layer2VIPConfig"
#     name : var.mgmt_vip_ip
#     link : "mgmt"
#   })
# }

# resource "null_resource" "apply_talos_link_configs" {
#   depends_on = [
#     local_file.mgmt_link_alias_config,
#     local_file.mgmt_link_config,
#     local_file.ceph_link_alias_config,
#     local_file.ceph_link_config,
#   ]

#   triggers = {
#     file_hashes = join(",", [
#       filesha256(local_file.mgmt_link_alias_config[*].filename),
#       filesha256(local_file.mgmt_link_config[*].filename),
#       filesha256(local_file.ceph_link_alias_config[*].filename),
#       filesha256(local_file.ceph_link_config[*].filename),
#     ])
#   }

#   for_each = local.nodes

#   provisioner "local-exec" {
#     command = <<EOT
#       for file in ${path.module}/../generated/node-${each.key}/*.json; do
#         talosctl apply-config \
#           --talosconfig ${path.module}/../_out/talosconfig \
#           --nodes ${each.value.mgmt_ip} \
#           --file $file
#       done
#     EOT
#   }
# }

# resource "null_resource" "apply_talos_vip_config" {
#   depends_on = [local_file.controlplane_vip]

#   triggers = {
#     file_hash = filesha256(local_file.controlplane_vip.filename)
#   }

#   for_each = {
#     for k, v in local.nodes : k => v if v.machine_type == "controlplane"
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       talosctl apply-config \
#         --talosconfig ${path.module}/../_out/talosconfig \
#         --nodes ${each.value.mgmt_ip} \
#         --file ${path.module}/../generated/controlplane/vip.json
#       done
#     EOT
#   }
# }

# data "talos_cluster_health" "this" {
#   depends_on = [
#     talos_machine_configuration_apply.this,
#     talos_machine_bootstrap.this
#   ]
#   skip_kubernetes_checks = false
#   client_configuration   = data.talos_client_configuration.this.client_configuration
#   control_plane_nodes    = [for k, v in local.nodes : v.mgmt_ip if v.machine_type == "controlplane"]
#   worker_nodes           = [for k, v in local.nodes : v.mgmt_ip if v.machine_type == "worker"]
#   endpoints              = data.talos_client_configuration.this.endpoints
#   timeouts = {
#     read = "10m"
#   }
# }

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  node                 = local.bootstrap_node
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/../talos/_out/kubeconfig"
}
