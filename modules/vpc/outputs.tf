output "vpc_id" {
  description = "VPC ID created by module"
  value = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the vpc create by this module"
  value = module.vpc.vpc_arn
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet ids"
  value = module.vpc.private_subnets
}

output "nat_public_ips" {
  description = "Nat gw EIPs"
  value = module.vpc.nat_public_ips
}

output "nat_gw_ids" {
  description = "Nat gw Ids"
  value = module.vpc.natgw_ids
}

output "azs" {
  description = "AZs supported by the module"
  value = data.aws_availability_zones.azs.names
}
