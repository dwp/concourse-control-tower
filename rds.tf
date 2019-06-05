resource "aws_db_subnet_group" "concourse" {
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_rds_cluster" "concourse" {
  cluster_identifier_prefix = "concourse-"
  engine                    = "aurora-postgresql"
  engine_version            = "10.7"
  availability_zones        = data.aws_availability_zones.main.names
  database_name             = "concourse"
  master_username           = var.database_user
  master_password           = var.database_password
  backup_retention_period   = 14
  preferred_backup_window   = "07:00-09:00"
  apply_immediately         = true
  db_subnet_group_name      = aws_db_subnet_group.concourse.id
  skip_final_snapshot       = true
  vpc_security_group_ids    = [aws_security_group.db.id]
  tags                      = var.tags
}

resource "aws_rds_cluster_instance" "concourse" {
  count              = var.database_count
  identifier_prefix  = "concourse-${local.zone_names[count.index]}-"
  engine             = aws_rds_cluster.concourse.engine
  engine_version     = aws_rds_cluster.concourse.engine_version
  availability_zone  = local.zone_names[count.index]
  cluster_identifier = aws_rds_cluster.concourse.id
  instance_class     = var.database_instance_class
  tags               = var.tags
}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    { Name = "db" }
  )
}

resource "aws_security_group_rule" "db_web_in" {
  from_port                = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  to_port                  = 5432
  type                     = "ingress"
  source_security_group_id = aws_security_group.web.id
}
