In order to get ansible to run docker_\* ansible modules on my laptop, I had to install
the Python `docker` module into the virtualenv that ansible was running from.
This was the same virtualenv that ansible had been used to bootstrap the
system from I believe.  Thus, I had to install it with the commands:

```
cd ~/ansible_tmp_python/bin
export PYTHONPATH=/home/mmackey/ansible_tmp_python:/home/mmackey/ansible_tmp_python/lib/python3.8/site-packages
./pip3 install docker
```

At this point, I had already installed docker on my laptop (using Ansible :) so
their may have been some Debian pre-reqs for the Python `docker` module that
a fresh Ubuntu install would not have met so this may not work alone to be
able to run docker_\* modules on a fresh Ubuntu system without bootstrapping
other Debian packages first.

