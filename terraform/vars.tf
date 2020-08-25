
variable "defaults" {
  type = map
  default = {
    environment = "elk-test"
  }
}

variable "vm" {
  type = map
  default = {
    ssh = {
      key_type = "RSA"
      key_bits = "2048"
    },
    storage = {
      root = 40
      extra = 60
    },
    ami = {
      owner-id = "137112412989" # Amazon
      name = "amzn2-ami-hvm-2.0.????????.?-x86_64-gp2"
    },
    instance = {
      type = "t2.micro"
    }
  }
}