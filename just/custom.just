# Assemble distrobox containers
assemble:
  echo 'Assembling and replacing distroboxes ...'
  distrobox assemble create --replace --file /etc/distrobox/distrobox.ini

# Rebase to a stock Bluefin image
devmode-off:
  #!/usr/bin/env bash
  CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
  if grep -q "bluefin-dx" <<< $CURRENT_IMAGE
  then
      echo "Rebasing to a non developer image"
      NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin-dx/bluefin/")
      rpm-ostree rebase $NEW_IMAGE
  else
      echo "You are currently not on a developer image"
  fi

# Rebase to the Bluefin Developer Experience image
devmode-on:
  #!/usr/bin/env bash
  CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')

  if grep -q "/var/ublue-os/image" <<< $CURRENT_IMAGE
  then
      echo ""
      echo "Before we can switch to the Bluefin Developer Experience"
      echo "the current system needs an update. Please run 'just update'"
      echo "and reboot your system when the update is finished."
      exit
  fi

  if grep -q "bluefin-dx" <<< $CURRENT_IMAGE
  then
      echo "You are already on a developer image"
  else
      echo "Rebasing to a developer image"
      NEW_IMAGE=$(echo $CURRENT_IMAGE | sed "s/bluefin/bluefin-dx/")
      rpm-ostree rebase $NEW_IMAGE
  fi

# Assemble a Pytorch distrobox (Nvidia only)
distrobox-mlbox:
  echo 'Assembling pytorch-nvidia mlbox distrobox ...'
  distrobox assemble create --file /usr/share/ublue-os/distrobox/pytorch-nvidia.ini

# Install recommended GNOME extensions
gnome-extensions:
  pip install --upgrade gnome-extensions-cli
  gext install tailscale-status@maxgallup.github.com
  gext install nightthemeswitcher@romainvigier.fr
  gext install pano@elhan.io
  gext install weatheroclock@CleoMenezesJr.github.io

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
jetbrains-toolbox:
  #!/usr/bin/env bash
  pushd "$(mktemp -d)"
  echo "Get latest JetBrains Toolbox version"
  # Get the json with latest releases
  curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
  # Extract information
  BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
  DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
  CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
  echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
  curl -sSfL -O "${DOWNLOAD_LINK}"
  curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
  tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
  echo "Launching JetBrains Toolbox"
  ./jetbrains-toolbox-"${BUILD_VERSION}"/jetbrains-toolbox

# Run the yafti setup tool
yafti:
  yafti /etc/yafti.yml --force

# Switch to the zsh shell
zsh:
  sudo usermod $USER --shell /usr/bin/zsh 
  printf "${USER}'s shell is now %s." "$(cat /etc/passwd | grep ":$UID:" | cut '-d:' '-f7')"

# Enable docker on the system
docker:
  sudo systemctl enable --now docker
  sudo usermod -aG docker $USER
  newgrp docker
