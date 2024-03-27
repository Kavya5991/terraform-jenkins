module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  #availability_zones   = var.availability_zones
}

module "autoscaling_group" {
  source                = "./modules/asg"
  vpc_id                = module.vpc.vpc_id
  //alb_security_group_id = [module.alb.alb_security_group_id]
  launch_template_name  = var.launch_template_name
  ami                   = var.ami
  instance_type         = var.instance_type
  desired_capacity      = var.desired_capacity
  max_size              = var.max_size
  min_size              = var.min_size
  public_subnet_ids     = module.vpc.public_subnet_ids
  target_group_arn      = [module.alb.target_group_arn]
  asg_security_group_id = [module.asg_security_group.sg_id]
}

module "alb" {
  source                  = "./modules/alb"
  alb_security_group_name = var.alb_security_group_name
  alb_name                = var.alb_name
  target_group_name       = var.target_group_name
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  alb_security_group_id   = [module.alb_security_group.sg_id]
}

module "alb_security_group" {
  source  = "./modules/sg"
  security_group_name        = "alb-security-group"  // Replace with your desired name
  security_group_description = "ALB Security Group"
  vpc_id                     = module.vpc.vpc_id

  ingress_rules = {
    http_from_internet = {
      description = "Allow jenkins port from alb"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress_rules = {
    allow_all_egress = {
      description = "Allow all egress traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

module "asg_security_group" {
  source  = "./modules/sg"
  security_group_name        = "asg-security-group"  // Replace with your desired name
  security_group_description = "ASG Security Group"
  vpc_id                     = module.vpc.vpc_id

  ingress_rules = {
    jenkins = {
      description = "Allow Jenkins traffic from ALB"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  egress_rules = {
    allow_all_egress = {
      description = "Allow all egress traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

