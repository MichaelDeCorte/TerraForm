
data "aws_ami" "linux_ami" {
     most_recent = true

     filter {
     	    name = "name"
	    values = ["amzn-ami-hvm*"]
     }

     filter {
     	    name = "architecture"
	    values = ["x86_64"]
     }

     filter {
     	    name = "root-device-type"
	    values = ["ebs"]
     }

     name_regex = "amzn-ami-hvm-[0-9\\.]*-x86_64-ebs"

     # who owns the image.  
     owners = [ "amazon" ]
}

