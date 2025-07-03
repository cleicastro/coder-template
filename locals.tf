locals {
  username = data.coder_workspace_owner.me.name
  common_labels = {
    "coder.owner"          = data.coder_workspace_owner.me.name
    "coder.owner_id"       = data.coder_workspace_owner.me.id
    "coder.workspace_id"   = data.coder_workspace.me.id
    "coder.workspace_name" = data.coder_workspace.me.name
  }
  coder_agent_metadata = [
    {
      display_name = "CPU Usage"
      key          = "0_cpu_usage"
      script       = "coder stat cpu"
      interval     = 10
      timeout      = 1
    },
    {
      display_name = "RAM Usage"
      key          = "1_ram_usage"
      script       = "coder stat mem"
      interval     = 10
      timeout      = 1
    },
    {
      display_name = "Home Disk"
      key          = "3_home_disk"
      script       = "coder stat disk --path $${HOME}"
      interval     = 60
      timeout      = 1
    },
    {
      display_name = "CPU Usage (Host)"
      key          = "4_cpu_usage_host"
      script       = "coder stat cpu --host"
      interval     = 10
      timeout      = 1
    },
    {
      display_name = "Memory Usage (Host)"
      key          = "5_mem_usage_host"
      script       = "coder stat mem --host"
      interval     = 10
      timeout      = 1
    },
    {
      display_name = "Load Average (Host)"
      key          = "6_load_host"
      script       = <<EOT
        echo "$(awk '{ print $1 }' /proc/loadavg) $(nproc)" | awk '{ printf "%0.2f", $1/$2 }'
      EOT
      interval     = 60
      timeout      = 1
    },
    {
      display_name = "Swap Usage (Host)"
      key          = "7_swap_host"
      script       = <<EOT
        free -b | awk '/^Swap/ { printf("%.1f/%.1f", $3/1024/1024/1024, $2/1024/1024/1024) }'
      EOT
      interval     = 10
      timeout      = 1
    }
  ]

}