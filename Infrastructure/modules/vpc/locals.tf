locals {
  vpc_netmask = {
    small  = 24,
    medium = 23,
    large  = 22
  }
  vpc_sizes = {
    small = {
      frontend_subnets_cidrs = {
        "az-a" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 4, 0),
          az   = data.aws_availability_zones.available.names[0]
        },
        "az-b" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 4, 1),
          az   = data.aws_availability_zones.available.names[1]
        },
        "az-c" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 4, 2),
          az   = data.aws_availability_zones.available.names[2]
        }
      },
      application_subnets_cidrs = {
        "az-a" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 5),
          az   = data.aws_availability_zones.available.names[0]
        },
        "az-b" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 6),
          az   = data.aws_availability_zones.available.names[1]
        },
        "az-c" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 7)
          az   = data.aws_availability_zones.available.names[2]
        }
      },
    },
    medium = {
      frontend_subnets_cidrs = {
        "az-a" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 0),
          az   = data.aws_availability_zones.available.names[0]
        },
        "az-b" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 1),
          az   = data.aws_availability_zones.available.names[1]
        },
        "az-c" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 2),
          az   = data.aws_availability_zones.available.names[2]
        }
      },
      application_subnets_cidrs = {
        "az-a" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 3),
          az   = data.aws_availability_zones.available.names[0]
        },
        "az-b" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 4),
          az   = data.aws_availability_zones.available.names[1]
        },
        "az-c" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 5)
          az   = data.aws_availability_zones.available.names[2]
        }
      },
    },
    large = {
      frontend_subnets_cidrs = {
        "az-a" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 0),
          az   = data.aws_availability_zones.available.names[0]
        },
        "az-b" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 1),
          az   = data.aws_availability_zones.available.names[1]
        },
        "az-c" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 2),
          az   = data.aws_availability_zones.available.names[2]
        }
      },
      application_subnets_cidrs = {
        "az-a" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 3),
          az   = data.aws_availability_zones.available.names[0]
        },
        "az-b" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 4),
          az   = data.aws_availability_zones.available.names[1]
        },
        "az-c" = {
          cidr = cidrsubnet(data.aws_vpc.workload.cidr_block, 3, 5)
          az   = data.aws_availability_zones.available.names[2]
        }
      },
    }
  }
}
