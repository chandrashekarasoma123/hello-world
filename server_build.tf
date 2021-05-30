resource "google_compute_instance" "kcs_server_inst" {
  for_each = var.server_build_info
  name         = each.value["name"]
  machine_type = each.value["server_type"]
  zone         = each.value["build_zone"]
  allow_stopping_for_update = true
  can_ip_forward            = true
  project = var.project

  tags = each.value["server_tags"]

  boot_disk {
    auto_delete = each.value["boot_auto_delete"]
    initialize_params {
      image = "${each.value["image_project"]}/${each.value["image_family"]}"
      size = each.value["boot_size"]
      type = each.value["boot_disk_type"]
    }
  }

  network_interface {
    // network = var.network
    subnetwork         = var.subnet
    subnetwork_project = var.subnet_project
    network_ip = each.value["network_ip_addr"]
    // Uncomment section below to give the VM an external ip address
    // access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_key_info.ssh_user}:${var.ssh_key_info.ssh_pub_key}"
  }

  metadata_startup_script = "sudo sed -i \"/$HOSTNAME/ {/kcscp.corp/! s/ / $HOSTNAME.kcscp.corp /1}\" /etc/hosts"

  attached_disk {
    source = google_compute_disk.gcp_inst_pd_swap[each.key].self_link
    device_name = "${each.value["name"]}-swap"
  }

  attached_disk {
    source        = google_compute_disk.gcp_inst_pd_tmp[each.key].self_link
    device_name = "${each.value["name"]}-tmp"
  }

  attached_disk {
    source        = google_compute_disk.gcp_inst_pd_data[each.key].self_link
    device_name = "${each.value["name"]}-data"
  }

  attached_disk {
    source        = google_compute_disk.gcp_inst_pd_backup[each.key].self_link
    device_name = "${each.value["name"]}-backup"
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }

  service_account {
    scopes = ["storage-full"]
  }
}

resource "google_compute_disk" "gcp_inst_pd_swap" {
  for_each = var.server_build_info
  project = var.project
  name    = "${each.value["name"]}-swap"
  type    = each.value["swap_disk_type"]
  zone    = each.value["build_zone"]
  size    = each.value["swap_size"]
}
/*
resource "google_compute_attached_disk" "gcp_app_attached_swap" {
  for_each = var.server_build_info
  project     = var.project
  device_name = "${each.value["name"]}-swap"
  disk        = google_compute_disk.gcp_inst_pd_swap[each.key].self_link
  instance    = google_compute_instance.kcs_server_inst[each.key].self_link
}
*/
resource "google_compute_disk" "gcp_inst_pd_tmp" {
  for_each = var.server_build_info
  project = var.project
  name    = "${each.value["name"]}-tmp"
  type    = each.value["tmp_disk_type"]
  zone    = each.value["build_zone"]
  size    = each.value["tmp_size"]
}
/*
resource "google_compute_attached_disk" "gcp_app_attached_tmp" {
  for_each = var.server_build_info
  project     = var.project
  device_name = "${each.value["name"]}-tmp"
  disk        = google_compute_disk.gcp_inst_pd_tmp[each.key].self_link
  instance    = google_compute_instance.kcs_server_inst[each.key].self_link
}
*/
resource "google_compute_disk" "gcp_inst_pd_data" {
  for_each = var.server_build_info
  project = var.project
  name    = "${each.value["name"]}-data"
  type    = each.value["data_disk_type"]
  zone    = each.value["build_zone"]
  size    = each.value["data_size"]
}
/*
resource "google_compute_attached_disk" "gcp_app_attached_data" {
  for_each = var.server_build_info
  project     = var.project
  device_name = "${each.value["name"]}-data"
  disk        = google_compute_disk.gcp_inst_pd_data[each.key].self_link
  instance    = google_compute_instance.kcs_server_inst[each.key].self_link
}
*/
resource "google_compute_disk" "gcp_inst_pd_backup" {
  for_each = var.server_build_info
  project = var.project
  name    = "${each.value["name"]}-backup"
  type    = each.value["backup_disk_type"]
  zone    = each.value["build_zone"]
  size    = each.value["backup_size"]
}
/*
resource "google_compute_attached_disk" "gcp_app_attached_backup" {
  for_each = var.server_build_info
  project     = var.project
  device_name = "${each.value["name"]}-backup"
  disk        = google_compute_disk.gcp_inst_pd_backup[each.key].self_link
  instance    = google_compute_instance.kcs_server_inst[each.key].self_link
}
*/
resource "google_compute_disk_resource_policy_attachment" "tmp_disk_attach" {
  for_each = var.server_build_info
  name = google_compute_resource_policy.snapshot_sched_policy.name
  project = var.project
  disk = "${each.value["name"]}-tmp"
  zone = each.value["build_zone"]
  depends_on = [
    google_compute_disk.gcp_inst_pd_tmp
  ]
}

resource "google_compute_disk_resource_policy_attachment" "data_disk_attach" {
  for_each = var.server_build_info
  name = google_compute_resource_policy.snapshot_sched_policy.name
  project = var.project
  disk = "${each.value["name"]}-data"
  zone = each.value["build_zone"]
  depends_on = [
    google_compute_disk.gcp_inst_pd_data
  ]
}

resource "google_compute_disk_resource_policy_attachment" "backup_disk_attach" {
  for_each = var.server_build_info
  name = google_compute_resource_policy.snapshot_sched_policy.name
  project = var.project
  disk = "${each.value["name"]}-backup"
  zone = each.value["build_zone"]
  depends_on = [
    google_compute_disk.gcp_inst_pd_backup
  ]
}

resource "google_compute_disk_resource_policy_attachment" "boot_disk_attach" {
  for_each = var.server_build_info
  name = google_compute_resource_policy.snapshot_sched_policy.name
  project = var.project
  disk = each.value["name"]
  zone = each.value["build_zone"]
  depends_on = [
    google_compute_instance.kcs_server_inst
  ]
}