# !/bin/bash
# Author:       Ayyanar Jeyakrishnan
# Email:        ayyanar.jeyakrishnan@jpmchase.com
# Date:         2018-07-14
# Usage:        script.sh [-a|--alpha] [-b=val|--beta=val]
# Description: Miniconda Installer with below option
###################################################################################
#   1) Download Miniconda installer
#   2) Run Miniconda installer to generate an isolated Python install
#   3) Install dependencies with Conda (if specified)
#   4) Install other dependencies with pip (if specified)
#   5) Install a local package archive (if specified)
#   6) Add the applications entry point to the path by:
#   7) Creating a new folder, Scripts, in the Miniconda directory
#   8) Sym-linking the entry script into the new folder
#   9) Adding the new folder to the user's path
#   10) Start the Jupyterhub Notebook
###################################################################################

# Name of application to install
AppName="YourApplicationName"

# Set your project's install directory name here
InstallDir="YourApplicationFolder"

# Dependencies installed by Conda
# Comment out the next line if no Conda dependencies
CondaDeps="numpy scipy scikit-learn pandas jupyterhub notebook"

# Install the package from PyPi
# Comment out next line if installing locally
PyPiPackage="mypackage"

# Local packages to install
# Useful if your application is not in PyPi
# Distribute this with a .tar.gz and use this variable
# Comment out the next line if no local package to install
LocalPackage="mypackage.tar.gz"

# Entry points to add to the path
# Comment out the next line of no entry point
#   (Though not sure why this script would be useful otherwise)
EntryPoint="YourApplicationName"

echo
echo "Installing $AppName"

echo
echo "Installing into: $(pwd)/$InstallDir"
echo

# Miniconda doesn't work for directory structures with spaces
if [[ $(pwd) == *" "* ]]
then
    echo "ERROR: Cannot install into a directory with a space in its path" >&2
    echo "Exiting..."
    echo
    exit 1
fi

# Test if new directory is empty.  Exit if it's not
if [ -d $(pwd)/$InstallDir ]; then
    if [ "$(ls -A $(pwd)/$InstallDir)" ]; then
        echo "ERROR: Directory is not empty" >&2
        echo "If you want to install into $(pwd)/$InstallDir, "
        echo "clear the directory first and run this script again."
        echo "Exiting..."
        echo
        exit 1
    fi
fi

# Download  Miniconda
set +e
curl "https://your_repository/miniconda/Miniconda-latest-Linux-x86_64.sh" -o Miniconda_Install.sh
if [ $? -ne 0 ]; then
    curl "http://your_repository/miniconda/Miniconda-latest-Linux-x86_64.sh" -o Miniconda_Install.sh
fi

# Install Miniconda

set -e
bash Miniconda_Install.sh -b -f -p $InstallDir

# Activate the new environment
PATH="$(pwd)/$InstallDir/bin":$PATH

# Make the new python environment completely independent
# Modify the site.py file so that USER_SITE is not imported
python -s << END
import site
site_file = site.__file__.replace(".pyc", ".py");
with open(site_file) as fin:
    lines = fin.readlines();
for i,line in enumerate(lines):
    if(line.find("ENABLE_USER_SITE = None") > -1):
        user_site_line = i;
        break;
lines[user_site_line] = "ENABLE_USER_SITE = False\n"
with open(site_file,'w') as fout:
    fout.writelines(lines)
END

# Install Conda Dependencies
if [[ $CondaDeps ]]; then
    conda install $CondaDeps -y
fi

# Install Package from PyPi
if [[ $PyPiPackage ]]; then
    pip install $PyPiPackage -q
fi

# Install Local Package
if [[ $LocalPackage ]]; then
    pip install $LocalPackage -q
fi

# Cleanup
rm Miniconda_Install.sh
conda clean -iltp --yes

# Add Entry Point to the path
if [[ $EntryPoint ]]; then

    cd $InstallDir
    mkdir Scripts
    ln -s ../bin/$EntryPoint Scripts/$EntryPoint

    echo "$EntryPoint script installed to $(pwd)/Scripts"
    echo
    echo "Add folder to path by appending to .bashrc?"
    read -p "[y/n] >>> " -r
    echo
    if [[ ($REPLY == "yes") || ($REPLY == "Yes") || ($REPLY == "YES") ||
        ($REPLY == "y") || ($REPLY == "Y")]]
    then
        echo "export PATH=\"$(pwd)/Scripts\":\$PATH" >> ~/.bashrc
        echo "Your PATH was updated."
        echo "Restart the terminal for the change to take effect"
    else
        echo "Your PATH was not modified."
    fi

    cd ..
fi

echo
echo "$AppName Install Successfully"

#Start the Hub server
set +e
netstat -an | grep "jupyter notebook list"
nbRet=$?
echo " Please find the action Notebook Session $nbRet"

if [ $nbRet -eq 0 ]; then
  echo "Starting the Jupyter Hub"
  jupyterhub
if 
