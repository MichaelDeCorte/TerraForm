
# output "keys" {
#     value = {
#         access_key = ""
#         secret_key = ""
#     }
# }

# output "tags" {
#     value  	 =    {
#         AdminContact = "Michael DeCorte"
#         Description = "sprizzi.io website"
# 		Owner	 = "Sprizzi"
# 		Project	 = "Sprizzi.io"
# 		Terraform = "true"
# 	}
# }

# output "variables" {
#     value  	 =    {
#         LOG_LEVEL = "debug"
# 	}
# }

# output "region" {
#     value    = "us-east-1"
#     description = "AWS region to launch servers."
# }

# output "profile" {
#     value    = "chainNinja"
#     description = "the profile in ~/.aws/credentials to use to access AWS"
# }

# output "id" {
#     value = "mdecorte"
# }

# output "keypair" {
#     value    = "sprizzi" 
#     description = "Desired name of AWS key pair"
# }

# # aws ec2 describe-availability-zones
# output "availability_zone" {
#     value    = "us-east-1d"
# }

# output "env" {
#     value    = "dev"
#     #value    = "prod"
#     #value    = "dev"
#     #value    = "demo"
#     description = "The name for the environment."
# }

# output "retention_in_days" {
#     value = "3"
# }

output "globals" {
    value = {
        keys = {
            access_key = ""
            secret_key = ""
        },

        tags  	 =    {
            AdminContact = "Michael DeCorte"
            Description = "sprizzi.io website"
            Owner	 = "Sprizzi"
            Project	 = "Sprizzi.io"
            Terraform = "true"
        },

        envVariables  	 =    {
            LOG_LEVEL = "debug"
        },

        region = {
            region = "us-east-1"
            availability_zone = "us-east-1d"
            environment = "dev" # "dev", "test", "demo", "prod"
        },

        awsProfile = {
            profile = "chainNinja"
        },

        keyPair = {
            keyPair = "sprizzi"
        },

        cloudWatch = {
            retention_in_days = "3"
        }
    }
}
