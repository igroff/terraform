locals {
  cluster_name_prefix = var.cluster_name
  container_port  = var.container_port
  container_image = var.container_image
}

data "aws_vpc" "target_vpc" {
  tags = {
    System = "rdnetinf"
  }
}

data "aws_subnet_ids" "cluster_subnet_ids" {
  vpc_id = data.aws_vpc.target_vpc.id

  tags = {
    System = "rdnetinf"
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  name_prefix          = join("-", [local.cluster_name_prefix, "asg"])
  launch_configuration = aws_launch_configuration.launch_config.name
  min_size             = 1     # convention (based on environment)
  max_size             = 2     # convention (based on environment)
  desired_capacity     = 0     # convention (based on environment)
  health_check_type    = "EC2" # cluster is running various containers, so ELB isn't right at this level
  vpc_zone_identifier  = data.aws_subnet_ids.cluster_subnet_ids.ids
  # forces terraform to delete the ASG even if the instances it manages are still running
  force_delete          = true
  protect_from_scale_in = false

  lifecycle {
    ignore_changes = [
      desired_capacity,
      tag,
    ]
  }

  # why the hell is this a done this way as oppsed to just a map? Appears to be 
  # due to reasons Terraform doesn't clarify
  dynamic "tag" {
    for_each = var.tags

    content {
      key    =  tag.key
      value   =  tag.value
      # this is complicated, so I'd like to make it true but haven't yet
      propagate_at_launch =  false
    }
  }
}

#This is gonna have to change from deploy to deploy, almost certainly to be generated
resource "aws_ecs_cluster" "cluster" {
  name = join("-", [local.cluster_name_prefix, "ecs-cluster"])

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = var.tags
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = join("-", [local.cluster_name_prefix, "latest-app-family"])
  container_definitions = templatefile("${path.module}/data/container-defs.json", { container_port = local.container_port, container_image = local.container_image })
  tags = var.tags
}

resource "aws_ecs_service" "ecs_service" {
  name                              = join("-", [local.cluster_name_prefix, "latest-app-service"])
  cluster                           = aws_ecs_cluster.cluster.id
  task_definition                   = aws_ecs_task_definition.task_definition.arn
  desired_count                     = 3
  health_check_grace_period_seconds = 0
  deployment_controller {
    type = "ECS"
  }
  propagate_tags = null

  load_balancer {
    container_name   = "latest-app-container"
    container_port   = local.container_port
    target_group_arn = aws_lb_target_group.target_group.arn
  }
  tags = var.tags
  # the relationship between the target group and the ALB is controlled by the listener, so
  # in some cases (without the depends_on) the service can attempt to set up it's relationship
  # with the target group BEFORE the target group and ALB are related via the listener, which
  # causes an error indicating the target group has no associated ALB. To prevent all this
  # we use depends_on to make sure the service waits for the listener creation.
  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "http_and_https_and_ssh" {
  name        = join("-", ["HTTP(S) Only", local.cluster_name_prefix])
  description = "Allow HTTP and HTTPs"
  vpc_id      = data.aws_vpc.target_vpc.id

  ingress {
    description = "Port 80 From Everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Port 443 From Everywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Port 22 From Everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "ecs_ephemeral_ports_security_group" {
  name        = join("-", ["Allow ECS Ephemeral Ports", local.cluster_name_prefix])
  description = "Allow ECS Ephemral Ports for Dynamic Port Mapping"
  vpc_id      = data.aws_vpc.target_vpc.id

  ingress {
    description = "Ephemeral Ports from ECS"
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.target_vpc.cidr_block]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.target_vpc.cidr_block]
  }

  ingress {
    description = "Docker"
    from_port   = 2375
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.target_vpc.cidr_block]
  }

  ingress {
    description = "Container Agent"
    from_port   = 51678
    to_port     = 51680
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.target_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

resource "aws_lb" "alb" {
  name               = join("-", [local.cluster_name_prefix, "alb"])
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.cluster_subnet_ids.ids
  tags = var.tags
  security_groups = [aws_security_group.http_and_https_and_ssh.id]
}

resource "aws_lb_target_group" "target_group" {
  name     = join("-", [local.cluster_name_prefix, "-tg"])
  port     = local.container_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.target_vpc.id
  stickiness {
    type = "lb_cookie"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "instance_ssm_s3_policy" {
  statement {
    actions = ["s3:GetObject"]

    resources = [
      "arn:aws:s3:::aws-ssm-us-east-2/*",
      "arn:aws:s3:::aws-windows-downloads-us-east-2/*",
      "arn:aws:s3:::amazon-ssm-us-east-2/*",
      "arn:aws:s3:::amazon-ssm-packages-us-east-2/*",
      "arn:aws:s3:::us-east-2-birdwatcher-prod/*",
      "arn:aws:s3:::patch-baseline-snapshot-us-east-2/*"
    ]

  }
}

resource "aws_iam_role" "instance_iam_role" {
  name               = join("-", [local.cluster_name_prefix, "iam-role"])
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  tags = var.tags
}

resource "aws_iam_role_policy" "ssm_s3_policy" {
  name   = join("-", [local.cluster_name_prefix, "ssm_s3_policy"])
  role   = aws_iam_role.instance_iam_role.id
  policy = data.aws_iam_policy_document.instance_ssm_s3_policy.json
}

resource "aws_iam_role_policy_attachment" "container_service_role_attachment" {
  role       = aws_iam_role.instance_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "container_service_role_attachment_ssm" {
  role       = aws_iam_role.instance_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cluster_instance_profile" {
  name = join("-", [local.cluster_name_prefix, "instance-profile"])
  role = aws_iam_role.instance_iam_role.name
}


# This is to fetch the recommened default ecs amazon linux AMI image for the regon we're in
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_configuration" "launch_config" {
  name_prefix                 = join("-", [local.cluster_name_prefix, "launch-config"])
  image_id                    = data.aws_ssm_parameter.ecs_ami.value
  instance_type               = var.cluster_instance_type
  iam_instance_profile        = aws_iam_instance_profile.cluster_instance_profile.name
  key_name                    = "superpants" #context
  user_data                   = templatefile("${path.module}/data/userdata.tmpl", { cluster-name = join("-", [local.cluster_name_prefix, "ecs-cluster"]) })
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ecs_ephemeral_ports_security_group.id, aws_security_group.http_and_https_and_ssh.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "ecr_repo" {
  name                 = join("-", [local.cluster_name_prefix, "repo"])
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}