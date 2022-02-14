# Construct the network
resource "google_compute_network" "vpc" {
    provider = google
    name = "vpc-${var.solution_name}"
    auto_create_subnetworks = false
}
# Construct the data subnet (with a secondary / alias ip range)
resource "google_compute_subnetwork" "native" {
    provider = google
    network = google_compute_network.vpc.id
    name = "subnet-native-${var.solution_name}"
    ip_cidr_range = "10.1.0.0/16"
    secondary_ip_range {
            ip_cidr_range = "10.2.0.0/16"
            range_name = "subnet-native-secondary-cluster-${var.solution_name}"
        }
    secondary_ip_range {
            ip_cidr_range = "10.3.0.0/16"
            range_name = "subnet-native-secondary-services-${var.solution_name}"
        }
        
    private_ip_google_access = true
    private_ipv6_google_access = true
}

# Configure Cloud NAT
resource "google_compute_router" "nat_router" {
  provider = google
  name     = "router-${var.solution_name}"
  network = google_compute_network.vpc.id
}
resource "google_compute_router_nat" "nat" {
  provider = google
  name                               = "nat-${var.solution_name}"
  router                             = google_compute_router.nat_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
# Allow traffic from IAP.
resource "google_compute_firewall" "iap" {
    provider = google
    name = "allow-ingress-iap"
    network = google_compute_network.vpc.id
    direction = "INGRESS"
    source_ranges = ["35.235.240.0/20"]

    allow {
        protocol = "tcp"
        ports = [
            "22",
            "3389"
        ]
    }
}
resource "google_compute_firewall" "icmp" {
    provider = google
    name = "allow-ingress-icmp"
    network = google_compute_network.vpc.id
    direction = "INGRESS"
    allow {
        protocol = "icmp"
    }
}