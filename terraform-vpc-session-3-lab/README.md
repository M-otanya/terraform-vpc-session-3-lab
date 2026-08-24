# Terraform VPC Practice Lab — Sessions 1 to 3

This repository is a guided beginner lab for practising the Terraform concepts covered through Session 3. It creates a small AWS network and teaches you how Terraform reads configuration, builds dependencies, produces plans, manages state, detects drift and destroys resources safely.

## What this lab creates

- One VPC with DNS support enabled
- One public subnet
- One private subnet
- One internet gateway attached to the VPC
- One public route table with a route to the internet gateway
- One association between the public subnet and public route table

The lab deliberately excludes EC2 instances, Elastic IP addresses and NAT Gateways. The network itself is simple and avoids the common hourly cost of a NAT Gateway. You are still responsible for checking your AWS account for any applicable charges.

## Dependency order

Terraform derives dependencies from references in the configuration. For example, `aws_subnet.public` refers to `aws_vpc.practice.id`, so the VPC must exist before the subnet.

Approximate creation order:

1. Read the available Availability Zones.
2. Create the VPC.
3. Create the public subnet, private subnet and internet gateway.
4. Create the public route table after both the VPC and internet gateway are ready.
5. Associate the public route table with the public subnet.

Destruction generally happens in reverse dependency order. Independent resources may be processed in parallel.

## Prerequisites

Install and configure:

- Terraform CLI
- AWS CLI
- An AWS account and credentials with permission to manage VPC resources
- A web browser, for viewing dependency graphs with Graphviz Online

Confirm the tools:

```powershell
terraform version
aws --version
aws sts get-caller-identity
```

Expected result:

- Terraform and AWS CLI print their versions.
- `aws sts get-caller-identity` returns your AWS account ID and the IAM identity Terraform will use.
- If the identity is unexpected, stop and correct your AWS profile before continuing.

If you use a named AWS profile, set it for the current PowerShell window:

```powershell
$env:AWS_PROFILE = "your-profile-name"
```

## Exercise 1 — Review and format the configuration

Clone the repository and enter its directory:

```powershell
git clone <YOUR-REPOSITORY-URL>
cd terraform-vpc-session-3-lab
```

Check formatting:

```powershell
terraform fmt -check
```

Expected result:

```text
No output and exit code 0
```

No output means the Terraform files are already correctly formatted. To automatically correct formatting, run:

```powershell
terraform fmt
```

Expected result: Terraform prints the name of each file it reformats. If nothing changes, it may print no filenames.

## Exercise 2 — Initialize the working directory

```powershell
terraform init
```

Expected result:

- Terraform downloads the AWS provider.
- A `.terraform` directory is created locally.
- `.terraform.lock.hcl` is created or updated.
- The command ends with `Terraform has been successfully initialized!`

The lock file should be committed to Git. The `.terraform` directory should not be committed.

## Exercise 3 — Validate the configuration

```powershell
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

Validation checks Terraform syntax and internal references. It does not prove that AWS will allow every operation.

## Exercise 4 — Examine variables and override defaults

This repository includes a `terraform.tfvars` file containing the actual non-sensitive values used by the lab. Terraform loads this file automatically. The included values select `us-east-1` and the `development` environment.

`terraform.tfvars.example` is a reusable template. Terraform does not load files ending in `.example` automatically.

Edit `terraform.tfvars` whenever you want to override a default declared in `variables.tf`. Do not put credentials, passwords or other secrets in a committed variable file.

You can also override one variable temporarily:

```powershell
terraform plan -var="environment=development"
```

Expected result: the plan shows the `Environment` tag as `development`, but no resources are changed unless you apply that plan or run apply with the same variable value.

## Exercise 5 — Create and inspect a saved plan

```powershell
terraform plan -out=tfplan
```

Expected result:

- Terraform refreshes data sources and calculates dependencies.
- The summary should show `Plan: 6 to add, 0 to change, 0 to destroy`.
- Terraform saves the plan as `tfplan`.

There are six managed objects: the VPC, two subnets, internet gateway, route table and route-table association. The Availability Zones block is a data source, so Terraform reads it rather than creates it.

Review the saved plan in human-readable form:

```powershell
terraform show tfplan
```

Expected result: Terraform displays the exact actions stored in the plan.

## Exercise 6 — Apply the saved plan

```powershell
terraform apply tfplan
```

Expected result:

- Terraform does not ask for another approval because you already supplied a saved plan.
- Resources are created according to their dependencies; independent resources may be created in parallel.
- The final summary should show `Apply complete! Resources: 6 added, 0 changed, 0 destroyed.`
- Terraform prints the output values, including the VPC and subnet IDs.

## Exercise 7 — Prove idempotency

Run another plan without changing the code:

```powershell
terraform plan
```

Expected result:

```text
No changes. Your infrastructure matches the configuration.
```

This demonstrates idempotency: applying the same desired configuration again should not recreate unchanged resources.

## Exercise 8 — Inspect Terraform state

List the managed resources:

```powershell
terraform state list
```

Expected result includes:

```text
aws_internet_gateway.practice
aws_route_table.public
aws_route_table_association.public
aws_subnet.private
aws_subnet.public
aws_vpc.practice
```

Inspect one resource:

```powershell
terraform state show aws_vpc.practice
```

Expected result: Terraform displays the VPC attributes currently recorded in state, including its ID, CIDR block and tags.

Display all state in a readable format:

```powershell
terraform show
```

Important: do not edit `terraform.tfstate` manually.

## Exercise 9 — Visualize the dependency graph

Terraform prints dependency information using the Graphviz DOT language. You can paste that output into [Graphviz Online](https://dreampuf.github.io/GraphvizOnline/) without installing Graphviz.

### Creation graph

Run:

```powershell
terraform graph -type=plan -draw-cycles
```

Copy the complete terminal output, beginning with:

```text
digraph {
```

and ending with the final closing brace:

```text
}
```

Open [Graphviz Online](https://dreampuf.github.io/GraphvizOnline/), remove its sample text and paste the Terraform output into the editor. The diagram is generated automatically. Use the website's download option to save the graph as an SVG or PNG image.

Expected result: the diagram shows the resources, variables, provider, outputs and dependency edges used during planning. The detailed plan graph contains Terraform internal operations, so it is more complicated than an ordinary architecture diagram. `-draw-cycles` highlights cycle edges if Terraform detects a circular dependency.

### Destroy graph

Run:

```powershell
terraform graph -type=plan-destroy -draw-cycles
```

Copy the complete `digraph` output, paste it into Graphviz Online and download the resulting SVG or PNG image.

Expected result: the destroy graph reverses the relevant dependency order so child resources can be removed before the resources they depend on. This command creates only a diagram; it does not destroy infrastructure.

Important: type the flags with normal keyboard hyphens (`-`). A copied long dash (`–`) is not a valid Terraform option.

## Exercise 10 — Create safe, intentional drift

Drift occurs when the real infrastructure changes outside Terraform and no longer matches the configuration or recorded state.

1. Open the AWS Console.
2. Go to **VPC > Your VPCs**.
3. Select the VPC whose Name is `terraform-session-3-lab-vpc`.
4. Edit its tags.
5. Change the `Environment` tag from `practice` to `changed-manually`.
6. Do not change or delete the CIDR block, subnets or routing.

Now run:

```powershell
terraform plan
```

Expected result:

- Terraform refreshes its understanding of the remote VPC.
- It reports that the VPC changed outside Terraform.
- The plan proposes an in-place update that changes `Environment` back to `practice`.
- The summary should show approximately `0 to add, 1 to change, 0 to destroy`.

The exact wording can vary by Terraform and AWS provider version.

## Exercise 11 — Compare two ways of handling drift

### Option A: Restore the configured value

Use this when the Terraform code is still the source of truth:

```powershell
terraform apply
```

Review the proposed tag correction, enter:

```text
yes
```

Expected result: Terraform changes the AWS tag back to `practice`. A following `terraform plan` reports no changes.

### Option B: Accept the remote change into state only

Repeat Exercise 10, then run:

```powershell
terraform plan -refresh-only
```

Expected result: Terraform proposes updating state to record the value currently in AWS without changing AWS infrastructure.

Apply the refresh-only plan:

```powershell
terraform apply -refresh-only
```

Expected result: state accepts the remote tag value. However, the configuration still says `practice`, so a later normal `terraform plan` proposes changing the AWS tag back to `practice`.

This distinction is important:

- A normal apply reconciles real infrastructure with configuration.
- A refresh-only apply reconciles state with real infrastructure.
- If you want to keep the manual value permanently, also update the Terraform configuration or variable value deliberately.

Before continuing, restore the configured value:

```powershell
terraform apply
```

## Exercise 12 — Practise configuration changes

Change this value in `terraform.tfvars`:

```hcl
environment = "development"
```

Format and review:

```powershell
terraform fmt
terraform validate
terraform plan
```

Expected result: Terraform proposes in-place tag changes rather than replacing the network.

Apply them:

```powershell
terraform apply
```

Enter `yes` when prompted. Expected result: the VPC and subnet tags are updated and the resource IDs remain unchanged.

## Exercise 13 — Inspect a destroy plan safely

Create a saved destroy plan:

```powershell
terraform plan -destroy -out="destroy.tfplan"
```

Expected result:

- The plan shows `0 to add, 0 to change, 6 to destroy`.
- Nothing has been deleted yet.
- The plan is stored in `destroy.tfplan`.

Review it:

```powershell
terraform show "destroy.tfplan"
```

Do not run `terraform apply "destroy.tfplan"` unless you are ready to remove the lab.

## Exercise 14 — Destroy the lab

When finished:

```powershell
terraform destroy
```

Review the plan carefully and enter:

```text
yes
```

Expected result:

- Terraform removes dependent resources before the resources they depend on.
- Independent deletions may happen in parallel.
- The command finishes with `Destroy complete! Resources: 6 destroyed.`

Confirm state is empty:

```powershell
terraform state list
```

Expected result: no resource addresses are printed.

## Command workflow to remember

```powershell
terraform fmt
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform state list
terraform show
terraform plan -destroy
terraform destroy
```

## Troubleshooting

### No valid credential sources found

Run:

```powershell
aws configure
aws sts get-caller-identity
```

Confirm that the expected IAM identity is returned.

### AccessDenied

The IAM identity does not have permission for one or more VPC actions. Read the error to identify the denied action and ask the account administrator for the minimum required permission.

### Error acquiring the state lock

Make sure no other Terraform command is running. Do not force-unlock state unless you have confirmed that the lock is stale and understand which operation created it.

### Region or Availability Zone errors

Confirm your selected region:

```powershell
terraform output aws_region
aws configure get region
```

The provider uses `var.aws_region`, which can differ from the AWS CLI default region.

### Graphviz Online reports a syntax error

Make sure you copied only the Terraform graph output, starting with `digraph {` and ending with its final `}`. Do not include the PowerShell prompt or unrelated terminal messages.

## Safety notes

- Always read a plan before applying it.
- Never commit state files, credentials or variable files containing secrets. The included `terraform.tfvars` contains only non-sensitive lab values.
- Do not manually edit Terraform state.
- Do not experiment with production infrastructure.
- Run `terraform destroy` after completing this practice lab.
