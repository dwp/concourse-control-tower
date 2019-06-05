resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

data "aws_availability_zones" "main" {}

locals {
  zone_count = length(data.aws_availability_zones.main.zone_ids)
  zone_names = data.aws_availability_zones.main.names
}

resource "aws_subnet" "public" {
  count                   = local.zone_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  vpc_id                  = aws_vpc.main.id
  availability_zone_id    = data.aws_availability_zones.main.zone_ids[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    var.tags,
    {
      Name = "public-${local.zone_names[count.index]}"
    }
  )
}

resource "aws_subnet" "private" {
  count                = local.zone_count
  cidr_block           = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + local.zone_count)
  vpc_id               = aws_vpc.main.id
  availability_zone_id = data.aws_availability_zones.main.zone_ids[count.index]
  tags = merge(
    var.tags,
    {
      Name = "private-${local.zone_names[count.index]}"
    }
  )
}

resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    var.tags,
    {
      Name = "public"
    }
  )
}

resource "aws_eip" "nat" {
  count = local.zone_count
  tags = merge(
    var.tags,
    {
      Name = "nat-${local.zone_names[count.index]}"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  count         = local.zone_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = merge(
    var.tags,
    {
      Name = "nat-${local.zone_names[count.index]}"
    }
  )
}

resource "aws_route_table" "private" {
  count  = local.zone_count
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    {
      Name = "private-${local.zone_names[count.index]}"
    }
  )
  route {
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
    cidr_block     = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "private" {
  count          = local.zone_count
  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}
