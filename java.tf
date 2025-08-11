resource "coder_agent" "java" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start.
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi
    
    ############## oh-my-zsh #############
    ZSH_CUSTOM="$${ZSH_CUSTOM:-/home/${local.username}/.oh-my-zsh/custom}"
    if [ ! -d "$${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions.git "$${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    fi

    if [ ! -d "$${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    fi
    ##############

    # Add any commands that should be executed at workspace startup (e.g install requirements, start a program, etc) here
    sudo dockerd &
  EOT

  # These environment variables allow you to make Git commits right away after creating a
  # workspace. Note that they take precedence over configuration defined in ~/.gitconfig!
  # You can remove this block if you'd prefer to configure Git manually or using
  # dotfiles. (see docs/dotfiles.md)
  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  dynamic "metadata" {
    for_each = local.coder_agent_metadata
    content {
      display_name = metadata.value.display_name
      key          = metadata.value.key
      script       = metadata.value.script
      interval     = metadata.value.interval
      timeout      = metadata.value.timeout
    }
  }
}

# See https://registry.coder.com/modules/coder/code-server
module "code-server" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/code-server/coder"

  # This ensures that the latest non-breaking version of the module gets downloaded, you can also pin the module version to prevent breaking changes in production.
  version = "~> 1.0"

  slug     = "code-server-java"
  agent_id = coder_agent.java.id
  order    = 1
}

resource "docker_container" "java" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.main.name
  name       = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname   = data.coder_workspace.me.name
  entrypoint = ["sh", "-c", replace(coder_agent.java.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.java.token}"]
  runtime    = "sysbox-runc"
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/${local.username}"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  dynamic "labels" {
    for_each = local.common_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}

resource "coder_script" "java_dotfiles" {
  agent_id     = coder_agent.java.id
  display_name = "Configuration environment for dev"
  icon         = "icon/terminal.svg"
  run_on_start = true
  script       = <<EOF
    #!/bin/sh
    coder dotfiles -y ${var.dotfiles_uri}
  EOF
}