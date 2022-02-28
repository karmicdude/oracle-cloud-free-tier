data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci.tenancy_ocid
}

data "oci_core_images" "image" {
  compartment_id = var.oci.tenancy_ocid
  display_name   = "Canonical-Ubuntu-20.04-Minimal-2021.12.03-0"
}

locals {
  compartment_id = data.oci_identity_availability_domains.ads.availability_domains[1].compartment_id
  ad_name        = data.oci_identity_availability_domains.ads.availability_domains[1].name
  image_id       = data.oci_core_images.image.images[0].id
}

resource "oci_core_virtual_network" "vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = local.compartment_id
  display_name   = "vcn"
  dns_label      = "vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = local.compartment_id
  display_name   = "igw"
  vcn_id         = oci_core_virtual_network.vcn.id
}

resource "oci_core_route_table" "rtb" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "rtb"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "acl" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "acl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "subnet" {
  cidr_block        = "10.0.1.0/24"
  display_name      = "subnet"
  dns_label         = "subnet"
  security_list_ids = [oci_core_security_list.acl.id]
  compartment_id    = local.compartment_id
  vcn_id            = oci_core_virtual_network.vcn.id
  route_table_id    = oci_core_route_table.rtb.id
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
}

resource "oci_core_instance" "wireguard" {
  # VM.Standard.E2.1.Micro available only in second ad
  availability_domain = local.ad_name
  compartment_id      = local.compartment_id
  display_name        = "wireguard"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    display_name              = "wireguard_vnic"
    assign_private_dns_record = false
    subnet_id                 = oci_core_subnet.subnet.id
    assign_public_ip          = true
  }

  source_details {
    source_type             = "image"
    source_id               = local.image_id
    boot_volume_size_in_gbs = 120
  }

  metadata = {
    ssh_authorized_keys = chomp(file(".keys/ansible.pub"))
  }
}

resource "cloudflare_record" "wireguard" {
  zone_id = var.zone_id
  name    = "wg.${var.root_domain}"
  value   = oci_core_instance.wireguard.public_ip
  type    = "A"
  ttl     = 120
  proxied = false
}

output "public_ip" {
  value = oci_core_instance.wireguard.public_ip
}
