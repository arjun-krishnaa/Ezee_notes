#!/bin/bash

USER="babu"
USER_HDIR="/home/$USER"
USERID="2223"
LOG_FILE="/home/log.txt"
PUBKEY_SOURCE="/home/authorized_keys"

# Create user
useradd -u "$USERID" -m -d "$USER_HDIR" -s /bin/bash "$USER"

# Set password (interactive)
passwd "$USER"

# Create .ssh directory
mkdir -p "$USER_HDIR/.ssh"

# Set permissions
chmod 700 "$USER_HDIR/.ssh"

# Create authorized_keys
touch "$USER_HDIR/.ssh/authorized_keys"

# Copy SSH public key
cp "$PUBKEY_SOURCE" "$USER_HDIR/.ssh/authorized_keys"

# Set permissions
chmod 600 "$USER_HDIR/.ssh/authorized_keys"
chown -R "$USER:$USER" "$USER_HDIR/.ssh"
chown -R "$USER:$USER" "$USER_HDIR/.ssh/authorized_keys"

# Add user to sudo group
usermod -aG sudo "$USER"

# Log output
{
  echo "Username: $USER"
  echo "User $USER created successfully."
} > "$LOG_FILE"

-------------------------------------------------------------------------
#!/bin/bash

USER="ashokk"
USER_HDIR="/home/$USER"
USERID="2227"
LOG_FILE="/home/log.txt"
PUBKEY_SOURCE="/home/authorized_keys"
SRC_DIR="/home"
DST_DIR="$USER_HDIR/.ssh"
FILEN="authorized_keys"

# Create user
useradd -u "$USERID" -m -d "$USER_HDIR" -s /bin/bash "$USER"

# Set password (interactive)
passwd "$USER"

# Create .ssh directory
mkdir -p "$USER_HDIR/.ssh"

# Set permissions
chmod 700 "$USER_HDIR/.ssh"

# Create authorized_keys
touch "$USER_HDIR/.ssh/authorized_keys"

# Copy SSH public key
cat "$PUBKEY_SOURCE" >> "$USER_HDIR/.ssh/authorized_keys"
#cp $SRC_DIR/$FILEN $DST_DIR

# Set permissions
chmod 600 "$USER_HDIR/.ssh/authorized_keys"
chown -R "$USER:$USER" "$USER_HDIR/.ssh"
chown -R "$USER:$USER" "$USER_HDIR/.ssh/authorized_keys"

# Add user to sudo group
usermod -aG sudo "$USER"

# Log output
{
  echo "Username: $USER"
  echo "User $USER created successfully."
} > "$LOG_FILE"



