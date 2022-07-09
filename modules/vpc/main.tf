data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  common_vpc_tags = merge(var.common_vpc_tags, { "kubernetes.io/cluster/${var.name_prefix}-eks" = "shared" })
  total_azs_count = length(data.aws_availability_zones.azs.zone_ids)
  newbits         = log(var.total_subnets, 2)
  all_subnets     = tolist([for i in range(var.total_subnets) : cidrsubnet(var.vpc_cidr, local.newbits, i)])
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr
  azs  = data.aws_availability_zones.azs.names

  # Split public and private subnets evenly. Not the best way but its okay for now
  public_subnets  = slice(local.all_subnets, 0, local.total_azs_count)
  private_subnets = slice(reverse(local.all_subnets), 0, local.total_azs_count)

  enable_nat_gateway            = true
  single_nat_gateway            = true # Save some $$$ but spof
  enable_dns_hostnames          = true
  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true
  reuse_nat_ips                 = false # Destroying VPC will release the EIP
  one_nat_gateway_per_az        = false # Save some $$$ but spof

  tags = var.common_vpc_tags

  default_network_acl_tags    = { Name = "${var.name_prefix}-eks" }
  default_route_table_tags    = { Name = "${var.name_prefix}-eks" }
  default_security_group_tags = { Name = "${var.name_prefix}-eks" }
  public_subnet_tags = merge(local.common_vpc_tags, {
    "kubernetes.io/role/elb" = "1"
  })
  private_subnet_tags = merge(local.common_vpc_tags, {
    "kubernetes.io/role/elb" = "1"
  })
}
