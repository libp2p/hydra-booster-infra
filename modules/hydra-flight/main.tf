data "aws_region" "current" {}

resource "aws_ecs_service" "hydra" {
  count                  = var.hydra_count
  name                   = "hydra-booster-${var.name}-${count.index}"
  cluster                = var.ecs_cluster_id
  task_definition        = aws_ecs_task_definition.hydra-booster[count.index].arn
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    subnets          = var.vpc_subnets
    security_groups  = var.security_groups
    assign_public_ip = true
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# note: to keep terraform from recreating this every time, keep the container definition JSON alphabetized
resource "aws_ecs_task_definition" "hydra-booster" {
  count                    = var.hydra_count
  family                   = "hydra-booster-${var.name}-${count.index}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  cpu                      = 4 * 1024  # max is 4*1024
  memory                   = 20 * 1024 # max is 30*1024
  tags                     = {}
  tags_all                 = {}
  container_definitions = jsonencode([
    {
      cpu   = 0
      image = var.hydra_image
      environment = concat(var.hydra_environment, [
        { name = "HYDRA_NAME", value = "${var.name}-${count.index}" },
        { name = "HYDRA_ID_OFFSET", value = tostring(count.index * var.hydra_nheads) }
      ])
      essential = true
      healthCheck = {
	# if a host is totally dead, we want to replace it
	# but if it's just really busy, we generally want to leave it alone
	# so these health checks are pretty liberal with lots of retries
	command = ["CMD-SHELL", "curl -fsS -o /dev/null localhost:8888/metrics || exit 1"],
	interval = 30, # seconds
	retries = 10,
	startPeriod = 300, # seconds
	timeout = 10 # seconds
      }
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = var.log_group_name,
          awslogs-region        = "${data.aws_region.current.name}",
          awslogs-stream-prefix = "ecs"
        }
      }
      mountPoints  = []
      name         = "hydra"
      portMappings = [{ containerPort = 8888, hostPort = 8888, protocol = "tcp" }]
      ulimits = [
        {
          name      = "nofile",
          hardLimit = 1048576,
          softLimit = 1048576
        }
      ]
      secrets     = var.hydra_secrets
      volumesFrom = []
    },
    {
      command = [
        "--prometheus.wal-directory=/etc/agent/data",
        "--enable-features=remote-configs",
        "--config.expand-env",
        "--config.file=${var.grafana_config_endpoint}"
      ]
      cpu   = 0
      image = "grafana/agent"
      environment = [
        # we use this for setting labels on metrics
        { name = "HYDRA_NAME", value = "${var.name}-${count.index}" }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = var.log_group_name,
          awslogs-region        = "${data.aws_region.current.name}",
          awslogs-stream-prefix = "ecs"
        }
      }
      mountPoints  = []
      name         = "grafana-agent"
      portMappings = []
      repositoryCredentials = {
        credentialsParameter = var.docker_pull_secret_arn
      }
      secrets     = var.grafana_secrets
      volumesFrom = []
    }
  ])
}
