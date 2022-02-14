# Create the GKE Cluster
# SEE FOR MORE DETAILS: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
# Also see: https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#gcloud

resource "google_container_cluster" "private_gke" {
    provider = google
    location = var.region
    name = "cluster-${var.solution_name}"
    network = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.native.id
    
    initial_node_count = 1
    # Since we NEED Shielded VMs, we need the seed node (which gets removed) to be shielded, too...
    node_config {
        preemptible = true
        machine_type = "n2d-standard-2"
        service_account = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
        oauth_scopes    = [
            "https://www.googleapis.com/auth/cloud-platform"
        ]
        shielded_instance_config {
          enable_secure_boot = true
          enable_integrity_monitoring = true
        }        
    }
    remove_default_node_pool = true


    enable_shielded_nodes = true

    private_cluster_config {
      enable_private_nodes = true
      enable_private_endpoint = true
      master_ipv4_cidr_block = "172.16.0.0/28"
    }

    # Maybe we can leave this blank since we need to use gcloud to add to list of master_authorized
    # dig +short myip.opendns.com @resolver1.opendns.com
    # gcloud container clusters update private-cluster-1 \
    # --enable-master-authorized-networks \
    # --master-authorized-networks EXISTING_AUTH_NETS,SHELL_IP/32
    # for EXISTING_AUTH_NETS: gcloud container clusters describe private-cluster-1 --format "flattened(masterAuthorizedNetworksConfig.cidrBlocks[])"

    # master_authorized_networks_config {
    #     cidr_blocks {
    #         cidr_block = "172.16.0.0/28"
    #     }
    # }

    master_authorized_networks_config {}
    
    ip_allocation_policy {
      cluster_secondary_range_name = "subnet-native-secondary-cluster-${var.solution_name}"
      services_secondary_range_name = "subnet-native-secondary-services-${var.solution_name}"
    }
}
resource "google_container_node_pool" "primary_spot_pool" {
    provider = google
    cluster = google_container_cluster.private_gke.id
    # node_count is per zone (3 zones, 2 nodes /zone => 6 nodes)
    node_count = 2
    node_config {
        preemptible = true
        machine_type = "n2d-highmem-2"
        service_account = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
        oauth_scopes    = [
            "https://www.googleapis.com/auth/cloud-platform"
        ]
        shielded_instance_config {
          enable_secure_boot = true
          enable_integrity_monitoring = true
        }
        disk_size_gb = 25
        disk_type = "pd-ssd"
        guest_accelerator = []
        image_type = "COS_CONTAINERD"

    }
}
