resource "aws_ecr_repository" "demo-deploy" {
  name = "demo-deploy" # Naming my repository
}

resource "aws_ecs_cluster" "demo-deploy" {
  name = "demo-deploy" # Naming the cluster
}

resource "aws_ecs_task_definition" "demo-deploy" {
  family                   = "demo-deploy" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "demo-deploy",
      "image": "${aws_ecr_repository.demo-deploy.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole1.arn
}

resource "aws_ecs_service" "demo-deploy" {
  name            = "demo-deploy"                           # Naming our first service
  cluster         = aws_ecs_cluster.demo-deploy.id          # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.demo-deploy.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers to 3

  load_balancer {
    target_group_arn = aws_lb_target_group.target-group.arn # Referencing our target group
    container_name   = aws_ecs_task_definition.demo-deploy.family
    container_port   = 3000 # Specifying the container port
  }

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    assign_public_ip = true                                                                                              # Providing our containers with public IPs
    security_groups  = [aws_security_group.http.id, aws_security_group.ingress-api.id, aws_security_group.egress-all.id] # Setting the security group
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole1.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole1" {
  name               = "ecsTaskExecutionRole1"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

