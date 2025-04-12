apt install -y lxterminal

XPRA_APP=lxterminal
XPRA_USER=user001
XPRA_USER_PASSWORD=123
sudo useradd -m -s /bin/bash $XPRA_USER && echo "$XPRA_USER:$XPRA_USER_PASSWORD" | sudo chpasswd
usermod -aG $(groups $USER | cut -d ":" -f2 | sed -e 's/^[[:space:]]*//g' | tr ' ' ',') $XPRA_USER

XPRA_USER_UID=$(id -u $XPRA_USER)
XPRA_USER_PORT=$(id -u $XPRA_USER)
XPRA_USER_DISPLAY=$(id -u $XPRA_USER)
XPRA_USER_HOME=$(getent passwd $XPRA_USER | cut -d: -f6)

mkdir /run/user/$XPRA_USER_UID
chown -R $XPRA_USER:$XPRA_USER /run/user/$XPRA_USER_UID
chmod -R 0700 /run/user/$XPRA_USER_UID
XDG_RUNTIME_DIR=/run/user/$XPRA_USER_UID
echo "export XDG_RUNTIME_DIR=\"$XDG_RUNTIME_DIR\"" >> $XPRA_USER_HOME/.bashrc

cd / && sudo -u $XPRA_USER xpra start :$XPRA_USER_DISPLAY \
 --bind-tcp=0.0.0.0:$XPRA_USER_PORT \
 --start=$XPRA_APP \
 --encodings=h264,vp9 \
 --quality=100 \
 --min-quality=80 \
 --speed=100 \
 --opengl=yes \
 --dpi=144 \
 --video-scaling=off \
 --no-pulseaudio \
 --env=XPRA_ALLOW_ROOT=1 \
 --no-mmap \
 --html=on \
 --env=XPRA_FORCE_COLOR_DEPTH=32 \
 --env=DISPLAY=:$XPRA_USER_DISPLAY \
 --no-notifications \
 --socket-dir=$XDG_RUNTIME_DIR
  
sudo -u $XPRA_USER xpra list

# sudo -u $USER xpra stop :100
# xpra start :100 --start-child=xclock --bind-tcp=0.0.0.0:10000 --html=on --start=xterm
# xpra start :100 --bind-tcp=0.0.0.0:10000 --html=on --start=xterm --env=XPRA_FORCE_COLOR_DEPTH=32   --env=DISPLAY=:100   --dpi=144
