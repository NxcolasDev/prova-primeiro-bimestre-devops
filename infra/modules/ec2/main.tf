data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.ec2_sg_id]
  iam_instance_profile   = "LabInstanceProfile"
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Atualiza pacotes
    dnf update -y

    # Instala Docker
    dnf install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    # Instala Docker Compose v2
    DOCKER_CONFIG=/usr/local/lib/docker
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
      -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    ln -sf $DOCKER_CONFIG/cli-plugins/docker-compose /usr/bin/docker-compose

    # Clona a aplicacao
    dnf install -y git
    git clone ${var.app_repo_url} /home/ec2-user/app
    chown -R ec2-user:ec2-user /home/ec2-user/app

    # Cria arquivo .env
    cat > /home/ec2-user/app/.env <<ENV
    DB_HOST=${var.db_host}
    DB_PORT=5432
    DB_USER=${var.db_user}
    DB_PASSWORD=${var.db_password}
    DB_NAME=${var.db_name}
    PORT=3000
    ENV

    # Sobe a aplicacao
    cd /home/ec2-user/app
    docker-compose up -d
  EOF

  tags = { Name = "${var.project}-ec2" }
}
