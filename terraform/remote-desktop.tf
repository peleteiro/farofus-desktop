resource "aws_key_pair" "desktop" {
  key_name   = "desktop"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_vpc" "desktop" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "desktop"
  }
}

resource "aws_subnet" "desktop" {
  vpc_id     = "${aws_vpc.desktop.id}"
  cidr_block = "10.0.1.0/24"

  tags {
    Name = "desktop"
  }
}

resource "aws_internet_gateway" "desktop" {
  vpc_id = "${aws_vpc.desktop.id}"
}

resource "aws_route_table" "desktop" {
  vpc_id = "${aws_vpc.desktop.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.desktop.id}"
  }
}

resource "aws_route_table_association" "desktop" {
  subnet_id      = "${aws_subnet.desktop.id}"
  route_table_id = "${aws_route_table.desktop.id}"
}

resource "aws_security_group" "desktop" {
  description = "Desktop"

  vpc_id = "${aws_vpc.desktop.id}"
  name   = "desktop"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8999
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

data "aws_ami" "desktop" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["379101102735"] # Debian
}

resource "aws_instance" "desktop" {
  ami                         = "${data.aws_ami.desktop.id}"
  instance_type               = "t2.xlarge"
  subnet_id                   = "${aws_subnet.desktop.id}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.desktop.id}"]
  key_name                    = "${aws_key_pair.desktop.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 60
  }

  user_data = <<EOF
#!/bin/sh
apt update
DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNEW=YES apt -y -o Dpkg::Options::="--force-confnew" full-upgrade

apt purge -y awscli

apt install -y apt-utils bash build-essential git tmux vim-nox curl wget apt-transport-https ca-certificates \
               gnupg2 dirmngr software-properties-common direnv python-pip

# Docker
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"

# Node 9.x
curl -sL https://deb.nodesource.com/setup_9.x | bash -

# Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Scala SBT
echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823

apt update
apt install -y nodejs yarn openjdk-8-jdk-headless sbt bc docker-ce

echo "${file("~/.ssh/id_rsa")}" | tee -a /home/admin/.ssh/id_rsa
chown admin /home/admin/.ssh/id_rsa
chmod 0600 /home/admin/.ssh/id_rsa

groupadd docker
usermod -aG docker admin
systemctl enable docker
systemctl restart docker

su --login admin -c 'pip install awscli --upgrade --user'

su --login admin -c 'ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts'
su --login admin -c 'git clone git@github.com:peleteiro/dotfiles.git'
su --login admin -c 'cd dotfiles && make'
su --login admin -c 'git clone git@github.com:biblebox/biblebox.git'
su --login admin -c 'cd biblebox && git submodule init && git submodule update'

apt autoremove -y

reboot
EOF

  tags {
    Name = "desktop"
  }
}

resource "cloudflare_record" "desktop" {
  domain  = "farofus.com"
  name    = "d"
  value   = "${aws_instance.desktop.public_ip}"
  type    = "A"
  proxied = false
}
