# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
set -e
set -x

NODE_ENV="production"

if id dirsrv >/dev/null 2>&1; then
    echo "User dirsrv already exists"
else
    echo "User dirsrv doesn't exist, adding it"
    sudo useradd -r -u 389 -s /sbin/nologin -d /usr/share/dirsrv dirsrv
fi

PIP="/usr/local/bin/pip3"
PYTHON="python3"
sudo dnf install -y "$PYTHON-devel" git make wget vim mlocate
sudo updatedb

# install pip
sudo curl -s https://bootstrap.pypa.io/get-pip.py | sudo $PYTHON

if [ ! -d "389-ds-base" ]; then
    # clone ds repo
    echo $REPO
    git clone -b "${BRANCH:-master}" "${REPO:-https://github.com/389ds/389-ds-base.git}" 389-ds-base
fi

# checkout pull request
if [ ! -z "${PR}" ]; then
    echo "$PR"
    pushd 389-ds-base
    git config --add remote.origin.fetch "+refs/pull/*:refs/remotes/origin/pr/*"
    git fetch
    git checkout "origin/pr/$PR/head"
    popd
fi

# checkout commit
if [ ! -z "${COMMIT}" ]; then
    pushd 389-ds-base
    git fetch --unshallow
    git checkout "$COMMIT"
    popd
fi

# apply a patch
if [ ! -z "${PATCH}" ]; then
    curl -s -O "$PATCH"
    pushd 389-ds-base
    git am "../$(basename $PATCH)"
    popd
fi

# build 389-ds-base with mock
sudo dnf builddep -y 389-ds-base
sudo dnf install -y mock rpm-build 389-ds-base cockpit-389-ds npm cargo
sudo usermod -a -G mock vagrant
pushd 389-ds-base
sed 's/npm run audit-ci//g' -i src/cockpit/389-console/node_modules.mk
sed 's/ifndef SKIP_AUDIT_CI//g' -i src/cockpit/389-console/node_modules.mk
sed 's/endif//g' -i src/cockpit/389-console/node_modules.mk

make -f rpm.mk clean

# enable ASAN
#if [ ! -z "${ASAN}" ]; then
#sed -i 's/CLANG_ON = 0/CLANG_ON = 1/g' rpm.mk
#sed -i 's/ASAN_ON = 0/ASAN_ON = 1/g' rpm.mk
#sed -i 's/MSAN_ON = 0/MSAN_ON = 1/g' rpm.mk
#sed -i 's/TSAN_ON = 0/TSAN_ON = 1/g' rpm.mk
#fi

make -f rpm.mk srpms
SRPM=$(ls -1 dist/srpms/)
MOCKRESULT="/var/lib/mock/fedora-33-x86_64/result"
mock -q "dist/srpms/$SRPM"
pushd $MOCKRESULT
gzip *log
RPM_NVRA=$(rpm -qp --qf "%{n}-%{v}-%{r}" $MOCKRESULT/*src.rpm) || true
MOCKREPO=/home/vagrant/repos/$RPM_NVRA
mkdir -p $MOCKREPO
cp -r $MOCKRESULT/* $MOCKREPO/
popd

sudo yum install -y policycoreutils-python-utils
sudo yum reinstall -y python3-setuptools python2-setuptools

sudo semanage port -a -t ldap_port_t -p tcp 38900-39299
sudo semanage port -a -t ldap_port_t -p tcp 63600-63999

# Install 389-ds-base from provided repo instead of the version from compose
pushd $MOCKREPO
sudo mv *src.rpm ../
sudo dnf install -y *rpm
popd

sudo ausearch -m AVC  | audit2allow

if [ ! -z "${REPL}" ]; then
    dscreate create-template inst1.inf
    sed -i 's/;root_password = Directory_Manager_Password/root_password = password/g' inst1.inf
    sed -i 's/;instance_name = localhost/instance_name = localhost1/g' inst1.inf
    sed -i 's/;port = 389/port = 38901/g' inst1.inf
    sed -i 's/;secure_port = 636/secure_port = 63601/g' inst1.inf
    sed -i 's/;create_suffix_entry = False/create_suffix_entry = True/g' inst1.inf
    sed -i 's/;sample_entries = no/sample_entries = yes/g' inst1.inf
    sed -i 's/;suffix =/suffix = dc=example,dc=com/g' inst1.inf
    cp inst1.inf inst2.inf
    sed -i 's/instance_name = localhost1/instance_name = localhost2/g' inst2.inf
    sed -i 's/port = 38901/port = 38902/g' inst2.inf
    sed -i 's/secure_port = 63601/secure_port = 63602/g' inst2.inf
    cp inst1.inf inst3.inf
    sed -i 's/instance_name = localhost1/instance_name = localhost3/g' inst3.inf
    sed -i 's/port = 38901/port = 38903/g' inst3.inf
    sed -i 's/secure_port = 63601/secure_port = 63603/g' inst3.inf

    sudo dscreate from-file inst1.inf
    sudo dscreate from-file inst2.inf
    sudo dscreate from-file inst3.inf

    cat >> replica1.ldif <<EOL
dn: cn=replica,cn=dc\\3Dexample\\2Cdc\\3Dcom,cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5Replica
cn: replica
nsDS5ReplicaRoot: dc=example,dc=com
nsDS5Flags: 1
nsDS5ReplicaType: 3
nsDS5ReplicaId: 1
nsDS5ReplicaBindDN: cn=replication manager,cn=config

dn: cn=replication manager,cn=config
changetype: add
objectClass: top
objectClass: netscapeServer
objectClass: nsAccount
cn: replication manager
userPassword: password

dn: cn=to2,cn=replica,cn=dc\\3Dexample\\2Cdc\\3Dcom,cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replicationagreement
cn: to2
nsDS5ReplicaRoot: dc=example,dc=com
description: to2
nsDS5ReplicaHost: localhost
nsDS5ReplicaPort: 38902
nsDS5ReplicaBindMethod: simple
nsDS5ReplicaTransportInfo: LDAP
nsDS5ReplicaBindDN: cn=replication manager,cn=config
nsDS5ReplicaCredentials: password

dn: cn=to3,cn=replica,cn=dc\\3Dexample\\2Cdc\\3Dcom,cn=mapping tree,cn=config
changetype: add
objectClass: top
objectClass: nsds5replicationagreement
cn: to3
nsDS5ReplicaRoot: dc=example,dc=com
description: to3
nsDS5ReplicaHost: localhost
nsDS5ReplicaPort: 38903
nsDS5ReplicaBindMethod: simple
nsDS5ReplicaTransportInfo: LDAP
nsDS5ReplicaBindDN: cn=replication manager,cn=config
nsDS5ReplicaCredentials: password
EOL

    cp replica1.ldif replica2.ldif
    sed -i 's/nsDS5ReplicaId: 1/nsDS5ReplicaId: 2/g' replica2.ldif
    sed -i 's/dn: cn=to2/dn: cn=to1/g' replica2.ldif
    sed -i 's/nsDS5ReplicaPort: 38902/nsDS5ReplicaPort: 38901/g' replica2.ldif

    cp replica2.ldif replica3.ldif
    sed -i 's/nsDS5ReplicaId: 2/nsDS5ReplicaId: 3/g' replica3.ldif
    sed -i 's/dn: cn=to3/dn: cn=to2/g' replica3.ldif
    sed -i 's/nsDS5ReplicaPort: 38902/nsDS5ReplicaPort: 38903/g' replica3.ldif

    #ldapmodify -h localhost -p 38901 -D "cn=directory manager" -w password -f replica1.ldif
    #ldapmodify -h localhost -p 38902 -D "cn=directory manager" -w password -f replica2.ldif
    #ldapmodify -h localhost -p 38903 -D "cn=directory manager" -w password -f replica3.ldif
else
    dscreate create-template inst.inf
    sed -i 's/;root_password = Directory_Manager_Password/root_password = password/g' inst.inf
    if [ ! -z "${SUFFIX}" ]; then
        sed -i 's/;create_suffix_entry = False/create_suffix_entry = True/g' inst.inf
        sed -i 's/;sample_entries = no/sample_entries = yes/g' inst.inf
        sed -i 's/;suffix =/suffix = dc=example,dc=com/g' inst.inf
    fi
    sudo dscreate from-file inst.inf
fi

git config --global user.email "spichugi@redhat.com"
git config --global user.name "Simon Pichugin"
echo "set -o vi" >> ~/.bashrc
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "fedora/33-cloud-base"
  #config.vm.network "private_network", type: "dhcp",  libvirt__network_name: "foo-network"

  config.vm.provision "shell", privileged: false, inline: $script, env: {
	  "REPO" => ENV["REPO"],
	  "BRANCH" => ENV["BRANCH"],
	  "PR" => ENV["PR"],
	  "COMMIT" => ENV["COMMIT"],
	  "PATCH" => ENV["PATCH"],
	  "ASAN" => ENV["ASAN"],
	  "SUFFIX" => ENV["SUFFIX"],
	  "REPL" => ENV["REPL"]
  }

  config.vm.provider "libvirt" do |v|
      v.memory = 2048
      v.cpus = 2
      v.qemu_use_session = false
  end

  config.vm.define "inst1", primary: true do |master1|
    master1.vm.box = "fedora/33-cloud-base"
  end

  config.vm.define "inst2", autostart: false do |master2|
    master2.vm.box = "fedora/33-cloud-base"
  end

  config.vm.define "inst3", autostart: false do |master3|
    master3.vm.box = "fedora/33-cloud-base"
  end

  #config.vm.network "forwarded_port", guest: 80, host: 8080
  #config.vm.network "forwarded_port", guest: 8080, host: 8080
  #config.vm.network "forwarded_port", guest: 5000, host: 5000
  #config.vm.network "forwarded_port", guest: 35357, host: 35357

  #config.vm.synced_folder ".", "/vagrant"
end
