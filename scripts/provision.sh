# vim:ft=sh
#!/bin/bash

/vagrant/scripts/prepare_build_environment.sh
/vagrant/scripts/fetch_build_inputs.sh
/vagrant/scripts/build_image.sh
