resource local_file name {
  filename     = "sample.txt"
  content      = " i love terraform"
  }
resource "google_compute_instance" "kcs_server_inst" {
  for_each = var.server_build_info