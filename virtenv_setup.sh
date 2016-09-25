#!/usr/bin/env bash

ask() {
    # http://djm.me/ask
    local prompt default REPLY

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -g|--github)
    GITHUB_LOC="$2"
    shift # past argument
    ;;
    -h|--help)
    printf "Command wrapper is to setup the virtual env for a python project and clone the github info\n\n\t-g <github location>:\tGithub location to clone"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

#if [ -z ${PROJ_NAME+x} ]; then
#    echo 'Project name not provided with -p|--project'
#    exit 1
#elif [ -z "$PROJ_NAME" -a "${PROJ_NAME+xxx}" = "xxx" ]; then
#    echo PROJ_NAME is set but empty
#    exit 1
#fi
if [ -z ${GITHUB_LOC+x} ]; then
    echo 'Github clone location not provided with -g|--github'
    exit 1
elif [ -z "$GITHUB_LOC" -a "${GITHUB_LOC+xxx}" = "xxx" ]; then
    echo GITHUB_LOC is set but empty
    exit 1
fi

# Step 1, required pip packages
echo "#############################"
echo "Make sure virtualenvwrapper installed"
echo "Ref:  http://virtualenvwrapper.readthedocs.io/en/latest/index.html"
echo ""
if [[ $(pip list) != *virtualenvwrapper* ]]; then
    echo "virtualenvwrapper doesn't appear to be installed"
    if [[ $EUID -ne 0 ]]; then
        echo "Running AS SUDO: pip install virtualenvwrapper"
        sudo pip install virtualenvwrapper
    else
        echo "Running: pip install virtualenvwrapper"
        pip install virtualenvwrapper
    fi
fi

echo "#############################"
echo "Make sure virtualenvwrapper installed"
echo "Ref:  https://github.com/FriendCode/giturlparse.py"
echo ""
if [[ $(pip list) != *giturlparse.py* ]]; then
    echo "giturlparse.py doesn't appear to be installed"
    if [[ $EUID -ne 0 ]]; then
        echo "Running AS SUDO: pip install giturlparse.py"
        sudo pip install giturlparse.py
    else
        echo "Running: pip install giturlparse.py"
        pip install giturlparse.py
    fi
fi

# Step 1a, make sure git is installed
echo "#############################"
echo "Making sure system has git installed"
echo ""
if ! type git > /dev/null; then
    if [[ $EUID -ne 0 ]]; then
        echo "Running git install with sudo b/c we're not root"
        if [ -n "$(command -v yum)" ]; then
            sudo yum install git
        elif [ -n "$(command -v apt-get)" ]; then
            sudo apt-get install git
        else
            echo "Not a yum or apt-get supported system"
        fi
    else
        echo "Running git install b/c we're root"
        if [ -n "$(command -v yum)" ]; then yum install git
        elif [ -n "$(command -v apt-get)" ]; then apt-get install git
        else
            echo "Not a yum or apt-get supported system"
        fi
    fi
fi

echo "#############################"
echo "Setup the virtualenvwrapper WORKON_HOME"
echo ""
echo ""
if [ -z ${WORKON_HOME+x} ]; then
    echo 'WORKON_HOME location not set'
    echo "Default setup is to use your home dir for virtualenv:  $HOME"
    if ask "Use this dir?" Y; then
        TMP_HOME=$HOME
        echo "CONFIRM::Using this dir-->$TMP_HOME"
    else
        echo -n "Enter new root dir: "
        read TMP_HOME
        while [ ! -d "$TMP_HOME" ]; do
            echo "Looks like that dir doesn't exist, try a new dir ($TMP_HOME)"
            echo -n "Enter new root dir: "
            read TMP_HOME
        done
        echo "CONFIRM::Using this dir-->$TMP_HOME"
    fi
    echo ""
    echo "Making sure virtualenvwrapper ENV vars set"
    if [ -f $HOME/.bashrc ]; then
        echo "Writing to $TMP_HOME/.bashrc"
        if ! grep -Fxq "WORKON_HOME=$TMP_HOME/.virtualenvs" $HOME/.bashrc
        then
            echo "virtualenv workon_home being set"
            echo "export WORKON_HOME=$TMP_HOME/.virtualenvs" >> $HOME/.bashrc
        fi
    else
        echo "~/.bashrc file doesn't seem to exist"
        exit 1
    fi
fi

echo "#############################"
echo "Setup the virtualenvwrapper PROJECT_HOME"
echo ""
echo ""
if [ -z ${PROJECT_HOME+x} ]; then
    echo 'PROJECT_HOME is not set!'
    echo "Default setup is to use your ~/Devel:  $HOME/Devel"
    if ask "Use this dir for development?" Y; then
        DEVEL_HOME="$HOME/Devel"
        mkdir -p "$DEVEL_HOME"
        echo "CONFIRM::Using this dir-->$DEVEL_HOME"
    else
        echo -n "Enter new root dir: "
        read DEVEL_HOME
        while [ ! -d "$DEVEL_HOME" ]; do
            echo "Looks like that dir doesn't exist, try a new dir ($DEVEL_HOME)"
            echo -n "Enter new root dir: "
            read DEVEL_HOME
        done
        echo "CONFIRM::Using this dir-->$DEVEL_HOME"
    fi
    echo ""
    echo "Making sure virtualenvwrapper ENV vars set"
    if [ -f $HOME/.bashrc ]; then
        if ! grep -Fxq "export PROJECT_HOME=$DEVEL_HOME" $HOME/.bashrc
        then
            echo "virtualenv project being set"
            echo "export PROJECT_HOME=$DEVEL_HOME" >> $HOME/.bashrc
        fi
        echo 'source `which virtualenvwrapper.sh`' >> $HOME/.bashrc
        source $HOME/.bashrc
    else
        echo "~/.bashrc file doesn't seem to exist"
        exit 1
    fi
fi
source `which virtualenvwrapper.sh`
echo "System confirmed setup for virtualenv"
echo ""

#echo ""
#echo "Setting up some helpers in the virtualenv"
##cat >$VIRTUAL_ENV/bin/postactivate << EOF
##cd () {
##    if (( $# == 0 ))
##    then
##        builtin cd $VIRTUAL_ENV
##    else
##        builtin cd "$@"
##    fi
##}
##
##EOF
##
##cat >$VIRTUAL_ENV/bin/postdeactivate << EOF
##cd () {
##    builtin cd "$@"
##}
##
##EOF

echo ""
echo "virtualenvwrapper setup, using mkproject for the github repo into this local dir:  $PROJECT_HOME"
STR='import giturlparse;uri="'"$GITHUB_LOC"'";res=giturlparse.parse(uri); print res.data["repo"]'
REPO=`python -c "$STR"`
echo "mkproject $REPO"
mkproject $REPO
source `which virtualenvwrapper.sh`
toggleglobalsitepackages

echo ""
echo "Git clone the project provided into the local project directory:  $PROJECT_HOME/$REPO"
cd $PROJECT_HOME
STR='import giturlparse;uri="'"$GITHUB_LOC"'";res=giturlparse.parse(uri); print res.data["protocol"]'
REQ_PROTOCOL=`python -c "$STR"`
STR='import giturlparse;uri="'"$GITHUB_LOC"'";res=giturlparse.parse(uri); print res.urls["ssh"]'
GITHUB_LOC_SSH=`python -c "$STR"`
if [ $REQ_PROTOCOL = 'ssh' ]; then
    echo "Nice, you're using ssh"
    echo "Just FYI, if you haven't setup your clients ssh keys for your profile.  Tip, create passwordless key to make git clones from github easier"
    echo "NOTE:  https://stackoverflow.com/questions/8588768/git-push-username-password-how-to-avoid/"
else
    echo "Requested github clone protocol is not SSH, instead string is:  $REQ_PROTOCOL"
    echo "I'm auto swtiching this to SSH, using this url: $GITHUB_LOC_SSH"
fi

git clone $GITHUB_LOC_SSH
toggleglobalsitepackages

echo "TODO:  read django project settings.py for env vars and append pre/post deployment virtualenv"

echo "Done - run 'workon `basename $GITHUB_LOC`'"
