#!/bin/bash

#------------------------------------------------------------------------------
# Purpose: Essentially emulate a virtualenv to install ansible to
#
# This is done so that we don't have to install any system-wide Python
# packages nor any .deb packages.
#------------------------------------------------------------------------------

TMP_PYTHON_DIR=~/ansible_tmp_python
TMP_PYTHON_BIN=${TMP_PYTHON_DIR}/bin/python3.8
GET_PIP_SCRIPT=${TMP_PYTHON_DIR}/get-pip.py

# Needed to make sure pip is installed to the tmp python instance; this is
# also needed in order to use the tmp pip once it is installed.
export PYTHONPATH=${TMP_PYTHON_DIR}:${TMP_PYTHON_DIR}/lib/python3.8/site-packages

# Not putting this script in `bin` or `local/bin` to make it very clear that this
# script is not part of the usual pip ansible install
ANSIBLE_BIN_SCRIPT=${TMP_PYTHON_DIR}/ansible.sh


#------------------------------------------------------------------------------
# Install system `distutils` package
#
#   - `get-pip.py` requires `distutils`
#------------------------------------------------------------------------------
install_system_distutils() {
  echo -e "\n#----[Install system distutils]------------------------------------"
  sudo apt install -y python3-distutils
}


#------------------------------------------------------------------------------
# Ubuntu 20.04 comes installed with Python 3.8 so we are making a copy of
# that system Python.  The installation is split across various directories
# notably being split between:
#  - /usr/lib/python3.8
#  - /usr/lib/python3
#------------------------------------------------------------------------------
make_tmp_python_from_system_python() {
  echo -e "\n#----[Make tmp python]-----------------------------------------"

  echo "Creating tmp python dir at: [${TMP_PYTHON_DIR}]"

  mkdir -p ${TMP_PYTHON_DIR}/{bin,lib}
  cp -r /usr/lib/python3.8             ${TMP_PYTHON_DIR}/lib 
  cp -r /usr/lib/python3/dist-packages ${TMP_PYTHON_DIR}/lib/python3.8/
  cp    /usr/bin/python3.8             ${TMP_PYTHON_BIN}
}


#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
download_get_pip_script() {
  echo -e "\n#----[Downoad get-pip.py]-----------------------------------------"

  wget https://bootstrap.pypa.io/get-pip.py -O ${GET_PIP_SCRIPT}
}


#------------------------------------------------------------------------------
# Ansible needs `setuptools` when it is installed with pip so we are not
# passing the `--no-setuptools` flag to `get-pip.py`; ansible also uses
# the `wheel` pip package when it is built (though it is not a hard
# requirement) so we don't pass the `--no-wheel` flag to `get-pip.py` either.
#------------------------------------------------------------------------------
install_pip_to_tmp_python() {
  echo -e "\n#----[Install pip]-----------------------------------------"

  ${TMP_PYTHON_BIN} ${GET_PIP_SCRIPT} --prefix=${TMP_PYTHON_DIR}
}


#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
install_ansible_to_tmp_python() {
  echo -e "\n#----[Install ansible]-----------------------------------------"

  ${TMP_PYTHON_DIR}/bin/pip3.8 install ansible
}


#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
create_ansible_bin_script() {
  echo -e "\n#----[Create ansible bin script]--------------------------------"

  cat > ${ANSIBLE_BIN_SCRIPT} <<END
#!/bin/sh
PYTHONPATH=${PYTHONPATH} ${TMP_PYTHON_DIR}/local/bin/ansible-playbook
END

  chmod +x ${ANSIBLE_BIN_SCRIPT}
}


#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
delete_tmp_python() {
  echo -e "\n#----[Delete tmp python]-----------------------------------------"
  rm -rf ${TMP_PYTHON_DIR}
}


#------------------------------------------------------------------------------
# Remove system `distutils` package
#------------------------------------------------------------------------------
purge_system_distutils() {
  echo -e "\n#----[Remove system distutils package]-----------------------------"
  sudo apt purge -y python3-distutils
}


#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
display_packages_installed() {
  echo -e "\n#----[Display installed packages]-------------------------------"

  echo -e "Here are the current packages installed to the tmp Python instance:\n\n"
  ${TMP_PYTHON_DIR}/bin/pip3.8 list -v
}


#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
print_help() {

  cat<<END


To run pip use:

PYTHONPATH=${PYTHONPATH} ${TMP_PYTHON_DIR}/bin/pip3.8 list -v

To run ansible use:

${ANSIBLE_BIN_SCRIPT}
END

}

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
main() {
  install_system_distutils
  make_tmp_python_from_system_python
  download_get_pip_script
  install_pip_to_tmp_python
  install_ansible_to_tmp_python
  create_ansible_bin_script
  purge_system_distutils
  display_packages_installed
  print_help
#  delete_tmp_python
}

main

