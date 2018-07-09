# 

/opt/terraform/terraform get -update

/opt/terraform/terraform plan
/opt/terraform/terraform apply

/opt/terraform/terraform show

/opt/terraform/terraform plan -distroy
/opt/terraform/terraform distroy

TODO
- user mdecorte instead of pivotal
- need an AMI.  Perhaps with www.packer.io

ISSUES
- debugging is hard....errors not helpful
- provisioniner can't be separated from resource
- execution from anyplace except project root is really bad

- no variable for project root
- module source doesn't support variables  :  "${path.root}/variables/chef"

- input variables can't be interpolated.   # see default tag for a pattern to support this

------------------------------------------------------------
Pattern for globally accessable variables
- define variables
  - create module in $TF_ROOT/variables/xxxx.tf
  - each variable is an "output" of the module
  - assumes variable names won't conflict
- use variables
  - in module add to the top:
     module "variables" {
     	      source = "../../variables"
	      }
  - use of variable XXXX
    	xxx = "${module.variables.XXXX}"

needs bug 1439 to be fixed so source can be $XXX/variables
https://github.com/hashicorp/terraform/issues/1439#issuecomment-303592145
  
------------------------------------------------------------
Best practice
- tag all TF created resources with Terraform:true

------------------------------------------------------------
Best Practice
- use separate state files for each env
https://charity.wtf/2016/03/30/terraform-vpc-and-why-you-want-a-tfstate-file-per-env/
