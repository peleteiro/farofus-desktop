resource "aws_key_pair" "desktop" {
  key_name   = "desktop"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_vpc" "desktop" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "desktop"
  }
}

resource "aws_subnet" "desktop" {
  vpc_id     = aws_vpc.desktop.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "desktop"
  }
}

resource "aws_internet_gateway" "desktop" {
  vpc_id = aws_vpc.desktop.id
}

resource "aws_route_table" "desktop" {
  vpc_id = aws_vpc.desktop.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.desktop.id
  }
}

resource "aws_route_table_association" "desktop" {
  subnet_id      = aws_subnet.desktop.id
  route_table_id = aws_route_table.desktop.id
}

resource "aws_security_group" "desktop" {
  description = "Desktop"

  vpc_id = aws_vpc.desktop.id
  name   = "desktop"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3999
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

resource "aws_eip" "desktop" {
  instance = aws_spot_instance_request.desktop.spot_instance_id
  domain   = "vpc"
}

data "aws_ami" "desktop" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"] # Debian
}

resource "aws_spot_instance_request" "desktop" {
  ami                         = data.aws_ami.desktop.id
  instance_type               = "t3.large"
  subnet_id                   = aws_subnet.desktop.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.desktop.id]
  key_name                    = aws_key_pair.desktop.id

  spot_price           = "0.1"
  spot_type            = "one-time"
  wait_for_fulfillment = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 200
  }

  user_data = <<EOF
#!/bin/sh
apt update
DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNEW=YES apt -y -o Dpkg::Options::="--force-confnew" full-upgrade

apt purge -y awscli

apt install -y \
        git zlib1g-dev wget tar gpg dirmngr automake autoconf libreadline-dev libncurses-dev libssl-dev libyaml-dev libxslt-dev libffi-dev libtool unixodbc-dev unzip curl \
        dumb-init bash curl hashdeep python3 build-essential locales jq apt-utils lsb-release apt-transport-https gpg-agent ca-certificates \
        gnupg gnupg2 software-properties-common direnv python3-pip rsync locales-all tmux neovim

# asdf
su --login admin -c ' \
  git clone https://github.com/asdf-vm/asdf.git /home/admin/.asdf --branch v0.12.0 && \
  chmod +x /home/admin/.asdf/asdf.sh && \
  echo "source /home/admin/.asdf/asdf.sh" >> /home/admin/.bash_profile && \
  echo "source /home/admin/.asdf/completions/asdf.bash" >> /home/admin/.bash_profile'

su --login admin -c 'asdf plugin-add nodejs'
su --login admin -c 'asdf plugin-add yarn'
su --login admin -c 'asdf plugin-add golang'
su --login admin -c 'asdf plugin-add python'
su --login admin -c 'asdf plugin-add terraform'
su --login admin -c 'asdf plugin-add java'
su --login admin -c 'asdf plugin-add awscli'
su --login admin -c 'asdf plugin-add flutter'
su --login admin -c 'asdf plugin-add jq'
su --login admin -c 'asdf plugin-add protoc'
su --login admin -c 'asdf plugin-add ripgrep'
su --login admin -c 'asdf plugin-add ruby'
su --login admin -c 'asdf plugin-add kotlin'

# Docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ssh key
echo "${file("~/.ssh/id_rsa")}" | tee -a /home/admin/.ssh/id_rsa
chown admin /home/admin/.ssh/id_rsa
chmod 0600 /home/admin/.ssh/id_rsa

groupadd docker
usermod -aG docker admin
systemctl enable docker
systemctl restart docker

su --login admin -c 'ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts'
su --login admin -c 'git clone git@github.com:peleteiro/dotfiles.git'
su --login admin -c 'cd dotfiles && make'
su --login admin -c 'git clone git@github.com:biblebox/biblebox.git'
su --login admin -c 'cd biblebox && git submodule init && git submodule update && asdf install'

apt autoremove -y
reboot
EOF

  tags = {
    Name = "desktop"
  }
}

resource "cloudflare_record" "desktop" {
  zone_id = "0d8789dd96c8237058e669fe8d4348e9" # peleteiro.dev
  name    = "d"
  value   = aws_eip.desktop.public_ip
  type    = "A"
  proxied = false
}
