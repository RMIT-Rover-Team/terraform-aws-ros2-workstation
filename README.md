# ROS2 Robotics EC2 — Terraform Setup

Provisions a GPU EC2 instance (`g4dn.xlarge`) on Ubuntu with a desktop
environment, NICE DCV remote desktop, and ROS2 Jazzy pre-installed via
`user_data`. Managed entirely with Terraform — create, update, and destroy
through the CLI, no manual console clicking.


<img src="demo.png" alt="Working Demo" width="400">


---

## Folder structure

```
terraform-ec2/
├── .gitignore
├── provider.tf                 # AWS provider config
├── variables.tf                # input variables + defaults
├── main.tf                     # security group + EC2 instance
├── outputs.tf                  # instance id, IP, DCV URL
├── terraform.tfvars            # actual values used for this deployment
└── scripts/
    ├── bootstrap.sh.tftpl      # cloud-init entrypoint (runs once, first boot)
    └── provision.sh.tftpl      # phased install script (survives the reboot)
```

Generated locally by Terraform, not committed to git (see `.gitignore`):

```
.terraform/                     # downloaded provider plugins
.terraform.lock.hcl             # provider version lock
terraform.tfstate               # current real-world state — never hand-edit
terraform.tfstate.backup        # previous state, auto-saved
```

---

## One-time local setup

1. **Install Terraform CLI**
   - macOS: 
    - `brew tap hashicorp/tap`
    - `brew install hashicorp/tap/terraform`
   - Verify: `terraform -version`

2. **Install AWS CLI**
   - macOS: 
    - `brew install awscli`
   - Verify: `aws --version`

3. **Create a root access key** (AWS Console → account name top-right →
   Security credentials → Access keys → Create access key)
   - This project uses root credentials rather than a dedicated IAM
     user — a deliberate choice for solo/personal use. See the
     **Security note** below before relying on this long-term.
   - If "Create access key" isn't available, root keys have been
     disabled at the account level (default for newer accounts) — you
     have to explicitly re-enable it under account settings.
   - Copy the Access Key ID and Secret Access Key immediately — the
     secret is only shown once.

4. **Configure credentials**
   ```bash
   aws configure
   ```
   Enter Access Key ID, Secret Access Key, region (`ap-southeast-2`),
   output format (`json`). Terraform's AWS provider reads these
   automatically — nothing to configure in the `.tf` files.

   > **Security note — using root credentials:** Root has unrestricted
   > access to the whole AWS account (billing, IAM, ability to delete
   > everything), with no permission boundary above it. AWS's own
   > guidance is to avoid root for everyday use. For this solo project
   > it's a reasonable tradeoff, but:
   > - Enable **MFA on the root account** regardless.
   > - Consider **deleting the access key when not actively using it**
   >   (Security credentials → Access keys → Deactivate/Delete) and
   >   regenerating when needed, rather than leaving a long-lived root
   >   key on disk.
   > - Never commit `~/.aws/credentials` anywhere — Terraform never
   >   asks for or stores credentials in the `.tf` files, so this risk
   >   is contained to your local machine only.
   > - If this ever becomes a shared or longer-lived project, switch to
   >   an IAM user with a scoped policy (e.g. `AmazonEC2FullAccess`)
   >   instead.

---

## Day-to-day workflow

| Step | Command | What it does |
|---|---|---|
| 1. Initialize | `terraform init` | Downloads the AWS provider plugin. Run once per machine/clone, or after adding a new provider. |
| 2. Preview | `terraform plan` | Shows what will be created/changed/destroyed. Nothing happens yet — always check this before applying. |
| 3. Apply | `terraform apply` | Creates/updates real AWS resources. Prompts for confirmation (`yes`). |
| 4. Inspect | `terraform output` | Prints `instance_id`, `public_ip`, `dcv_url`. |
| 5. Tear down | `terraform destroy` | Deletes everything Terraform is tracking (instance + security group). Prompts for confirmation. |

**Making changes:** edit the `.tf` files or `terraform.tfvars`, then repeat
steps 2–3. Terraform diffs against state and only touches what changed.

**State file (`terraform.tfstate`):** this is Terraform's memory of what
it created. Keep it — losing it means Terraform "forgets" the resources
exist (they'll keep running in AWS, but you'd have to `terraform import`
them back in to manage them again). 

---

## Accessing the instance - Connecting via NICE DCV
 
Get the instance's current public IP first:
```bash
terraform output public_ip
```
 
> **Note:** the public IP changes on every stop/start (or
> destroy/apply) cycle since this setup uses the default auto-assigned
> IP, not an Elastic IP. Re-check the output each time before
> connecting — don't bookmark a fixed address.
 
**Login:** `ubuntu` / `ubuntu` (set by the
provisioning script — change this if the instance is ever exposed
long-term).
 
### DCV Viewer app
 
Download from [amazondcv.com](https://www.amazondcv.com/).
 
1. Open the app.
2. Enter `<public_ip>`.
3. Accept the same self-signed certificate trust prompt on first
   connect — the app remembers it after that.
4. Log in as `ubuntu`.


---

## GitHub access (deploy key)

Each instance generates its own SSH key during provisioning (Phase 2)
rather than reusing your laptop's personal GitHub key — if the
instance is ever compromised or torn down, you just revoke this one
key on GitHub instead of your main identity.

**Retrieving the public key after `apply`:**
- Open a terminal in the DCV desktop session and run:
  ```bash
  cat ~/github_deploy_key.pub
  ```
- Or check `/var/log/provision.log` — it's printed clearly between
  `====` banners near the end of the Phase 2 output.

**Adding it to GitHub (per repo):**
1. Go to the repo → **Settings → Deploy keys → Add deploy key**.
2. Paste the public key.
3. Check **"Allow write access"** only if you need to `push`, not just
   `pull`.

**Test from the instance:**
```bash
ssh -T git@github.com
```

Because this key is generated fresh every time the instance is
rebuilt, you'll need to re-add it as a deploy key after each full
`destroy` → `apply` cycle (not needed for plain reboots/updates —
the key persists on the EBS volume as long as the instance itself
isn't destroyed).

---
 
## How long until the instance is actually ready
 
**`public_ip` being displayed is fast (~1-2 min) but misleading.**
`terraform apply` returns as soon as AWS reports the instance
`running` with a public IP assigned — that's a networking-layer check
only. It says nothing about what's happening inside the OS, which is
still mid-provisioning at that point.
 
**Actual readiness takes ~10-15 minutes**.
 
**Don't try connecting via DCV right after `apply` returns** — the
`dcvserver` isn't running yet, so the connection will just fail. Wait
~10-15 minutes, then try the app. If it's not up yet, wait a bit
longer and retry — there's no harm in retrying, the connection simply
refuses until Phase 2 finishes and `dcvserver` starts.
 
---

## Spot instances (optional, cheaper)
 
`g4dn.xlarge` spot pricing is typically **50-70% cheaper** than
on-demand. Supported via a toggle in `terraform.tfvars`:
 
```hcl
use_spot_instance = true
spot_max_price    = "0.25"   # your max hourly bid in USD; omit to default to on-demand price as cap
```
 
Then `terraform apply` as usual — same instance, same provisioning,
just billed as spot.
 
**Tradeoff to know before enabling:** AWS can interrupt a spot
instance with as little as ~2 minutes' notice if it reclaims capacity
or the price rises above your bid. Given this box takes ~10 minutes to
provision and is used as an interactive desktop (DCV session), an
interruption mid-work is more disruptive here than for a typical
background/batch job.
 
To keep this predictable, this config uses:
- `spot_instance_type = "one-time"` + `instance_interruption_behavior =
  "terminate"` — on interruption, the instance is terminated outright
  (matches on-demand's usual lifecycle — no lingering stopped
  instance, no surprise storage charges from a stopped-but-not-deleted
  box).
- **Full re-provisioning on next `apply`.** Since termination deletes
  the EBS root volume, a fresh instance means Phase 1 → reboot →
  Phase 2 runs again from scratch (~10-15 min), and a new GitHub deploy
  key gets generated (re-add it to the repo's deploy keys).
**Spot request lifecycle / does Terraform cancel it?**
 
What you *do* lose on interruption: your active DCV session, unsaved
in-memory work, and the provisioned environment itself (since it's not
preserved). Save work periodically if running on spot, and expect to
re-provision if interrupted.
 
**Switching between spot and on-demand:**
```hcl
# terraform.tfvars
use_spot_instance = true    # or false
spot_max_price    = "0.25"  # ignored when use_spot_instance = false
```
then `terraform plan && terraform apply`.
 
`instance_market_options` is a launch-time attribute — it can't be
changed on a running instance, so toggling this always shows as
`-/+ aws_instance.ros2_robotics (destroy and then create)` in the
plan, never an in-place update. Practically this means switching
either direction = full re-provisioning (~20 min), a new public IP,
and a new GitHub deploy key to re-add — same cost as a manual
`destroy` + `apply`. The security group is untouched either way.
 
Switch back to on-demand any time by setting `use_spot_instance =
false` (or removing the line) and re-applying — Terraform will
recreate the instance under the new pricing model since
`instance_market_options` forces a replacement.

---

## Things to check/update before applying

- [ ] `allowed_cidr` in `terraform.tfvars` — defaults to `0.0.0.0/0`
      (open to the internet on ports 22 and 8443). Narrow to your own
      IP (`x.x.x.x/32`) if this will be up for more than a quick test.
- [ ] Confirm the AMI (`ami_id`) still exists in your target region —
      AMI IDs can be deprecated/replaced over time.
- [ ] `g4dn.xlarge`/`g5.xlarge`/`g6.xlarge` are paid GPU instances — remember to
      `terraform destroy` (or at least stop the instance) when not in
      use. Provisioning alone takes ~10–15 minutes before ROS2 is fully
      installed.

---

## Useful commands

```bash
terraform fmt              # auto-format .tf files
terraform validate         # check syntax without hitting AWS
terraform show             # dump current state in human-readable form
terraform state list       # list resources Terraform is tracking
terraform destroy -target=aws_instance.ros2_robotics   # destroy just one resource
```
