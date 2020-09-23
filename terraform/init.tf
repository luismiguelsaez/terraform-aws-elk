data "aws_ami" "default" {
  most_recent = true
  owners = [ var.vm.ami.owner-id ]

  filter {
    name   = "name"
    values = [ var.vm.ami.name ]
  }
}

resource "aws_key_pair" "main" {
  key_name   = var.defaults.environment
  public_key = tls_private_key.main.public_key_openssh
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.default.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  associate_public_ip_address = true

  key_name = aws_key_pair.main.key_name

  subnet_id = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.public.id]

  tags = {
    Name = format("%s-bastion",var.defaults.environment)
    environment = var.defaults.environment
  }
}

resource "aws_instance" "public" {
  count = 2

  ami           = data.aws_ami.default.id
  instance_type = "t3.small"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  key_name = aws_key_pair.main.key_name

  #user_data = file("files/docker/amazon-linux.sh")

  subnet_id = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.public.id]

  tags = {
    Name        = format("%s-kibana-%02d",var.defaults.environment, count.index + 1)
    environment = var.defaults.environment
    exposition  = "public"
    stack       = "elk"
    application = "kibana"
  }
}

resource "aws_instance" "private_data" {
  count = 3

  ami           = data.aws_ami.default.id
  instance_type = "t3.large"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  associate_public_ip_address = false

  key_name = aws_key_pair.main.key_name

  #user_data = file("files/docker/amazon-linux.sh")

  subnet_id = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.private.id]

  tags = {
    Name        = format("%s-elasticsearch-data-%02d",var.defaults.environment, count.index + 1)
    environment = var.defaults.environment
    exposition  = "private"
    stack       = "elk"
    application = "elasticsearch"
    node_role   = "data"
  }
}

resource "aws_instance" "private_ingest" {
  count = 2

  ami           = data.aws_ami.default.id
  instance_type = "t3.large"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  associate_public_ip_address = false

  key_name = aws_key_pair.main.key_name

  #user_data = file("files/docker/amazon-linux.sh")

  subnet_id = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.private.id]

  tags = {
    Name        = format("%s-elasticsearch-ingest-%02d",var.defaults.environment, count.index + 1)
    environment = var.defaults.environment
    exposition  = "private"
    stack       = "elk"
    application = "elasticsearch"
    node_role   = "ingest"
  }
}