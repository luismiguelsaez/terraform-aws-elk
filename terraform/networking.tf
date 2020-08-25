resource "aws_vpc" "main" {
  cidr_block = "10.5.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    environment = var.defaults.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    environment = var.defaults.environment
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    environment = var.defaults.environment
    exposition = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    environment = var.defaults.environment
    exposition = "private"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)

  map_public_ip_on_launch = true

  tags = {
    Name = format("%s-public-%02d",var.defaults.environment, count.index + 1)
    environment = var.defaults.environment
    az = data.aws_availability_zones.available.names[count.index]
  }
}

resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(data.aws_availability_zones.available.names))

  tags = {
    Name = format("%s-private-%02d",var.defaults.environment, count.index + 1)
    environment = var.defaults.environment
    az = data.aws_availability_zones.available.names[0]
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "public" {
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kibana HTTP external"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Monitoring ports"
    from_port   = 9600
    to_port     = 9610
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-private",var.defaults.environment)
    environment = "test"
    exposition  = "public"
  }
}

resource "aws_security_group" "private" {
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Logstash pipelines"
    from_port   = 5044
    to_port     = 5050
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Monitoring ports"
    from_port   = 9600
    to_port     = 9610
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "ES HTTP"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "ES Discover"
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-private",var.defaults.environment)
    environment = "test"
    exposition  = "private"
  }
}

resource "aws_lb" "main" {
  name               = var.defaults.environment
  load_balancer_type = "application"
  internal           = false

  security_groups    = [ aws_security_group.public.id ]
  subnets            = aws_subnet.public.*.id

  tags = {
    Name = format("%s",var.defaults.environment)
    environment = "test"
    exposition  = "public"
  }
}

resource "aws_lb_listener" "kibana" {
  load_balancer_arn = aws_lb.main.arn
  port              = "5601"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana.arn
  }
}

resource "aws_lb_target_group" "kibana" {
  name     = format("%s-kibana",var.defaults.environment)
  port     = 5601
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener_rule" "kibana" {
  listener_arn = aws_lb_listener.kibana.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_target_group_attachment" "kibana" {
  count = length(aws_instance.public)

  target_group_arn = aws_lb_target_group.kibana.arn
  target_id        = aws_instance.public[count.index].id
  port             = 5601
}
