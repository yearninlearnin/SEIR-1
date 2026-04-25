resource "google_compute_instance" "vm" {
  name         = "lab-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id

    # External IP for SSH (lab simplicity)
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y git
    sudo apt-get install -y git nginx

    sudo systemctl enable nginx
    sudo systemctl start nginx


    cd /tmp
    sudo git clone https://github.com/BalericaAI/SEIR-1.git

    sudo chmod +x /tmp/SEIR-1/weekly_lessons/weeka/userscripts/supera.sh
    sudo bash /tmp/SEIR-1/weekly_lessons/weeka/userscripts/supera.sh
  EOT

  tags = ["ssh", "http", "http-server"]

  depends_on = [
    google_compute_subnetwork.private,
    google_compute_router_nat.nat
  ]
}
