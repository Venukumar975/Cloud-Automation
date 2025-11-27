import yaml
import sys

yaml_path = sys.argv[1]

with open(yaml_path, 'r') as f:
    data = yaml.safe_load(f)

# Flatten 1st level nested sections (keeps VPC working)
flat = {}
for key, value in data.items():
    if isinstance(value, dict):
        for sub_key, sub_val in value.items():
            flat[sub_key] = sub_val
    else:
        flat[key] = value

# ---- SAFE FIX: MAP TO TERRAFORM NAMES ----

# Compute scaling
if "compute" in data:
    scaling = data["compute"].get("scaling", {})
    flat["min_instances"] = scaling.get("min")
    flat["max_instances"] = scaling.get("max")
    flat["desired_instances"] = scaling.get("desired")

# Database rename & mapping
if "database" in data:
    db = data["database"]
    flat["enable_rds"] = db.get("enable")
    flat["db_engine"] = db.get("engine")
    flat["db_version"] = db.get("version")
    flat["db_instance_class"] = db.get("instance_class")
    flat["db_storage"] = db.get("storage_gb")
    flat["db_multi_az"] = db.get("multi_az")
    flat["db_public"] = db.get("publicly_accessible")

# Cache rename & mapping
if "cache" in data:
    cache = data["cache"]
    flat["enable_redis"] = cache.get("enabled")
    flat["cache_node_type"] = cache.get("node_type")
    flat["cache_num_nodes"] = cache.get("num_nodes")

# generate frontend flags
if "frontend" in data:
    fe = data["frontend"]
    flat["frontend_enabled"] = fe.get("enabled", False)


# ---- REMOVE WRONG YAML KEYS THAT BREAK TF ----
for wrong in ["enable", "version", "engine", "instance_class", "storage_gb", "publicly_accessible", "enabled", "node_type", "num_nodes", "scaling"]:
    flat.pop(wrong, None)

# ---- TO HCL (KEEP VPC FORMAT EXACT SAME) ----
def to_hcl(value):
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, (int, float)):
        return value
    if isinstance(value, list):
        return "[" + ", ".join(f"\"{v}\"" for v in value) + "]"
    return f"\"{value}\""

# ---- WRITE terraform.tfvars FILE ----
output_path = "infra/env/prod/terraform.tfvars"

with open(output_path, "w") as f:
    for key, value in flat.items():
        f.write(f"{key} = {to_hcl(value)}\n")

print(f"🎉 Generated {output_path}")

