data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  service_name = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_id = aws_vpc.main.id

  route_table_ids = concat(
    aws_route_table.private[*].id,
    aws_default_route_table.public[*].id
  )
  tags  = var.tags
}
