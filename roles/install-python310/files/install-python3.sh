# Install Development Tools and Libraries
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel bzip2-devel libffi-devel zlib-devel

# Download and extract Python 3.10 source code
cd /home/deploy
sudo wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz
sudo tar xzf Python-3.10.0.tgz
cd Python-3.10.0

# Build and install Python 3.10
sudo ./configure --enable-optimizations
sudo make altinstall

source ~/.bashrc

# Verify the installation
python3.10 --version

# symlink to /usr/bin/python3
sudo ln -s /usr/local/bin/python3.10 /usr/bin/python3

# (Optional) Set up a virtual environment
python3.10 -m ensurepip --upgrade
python3.10 -m pip install --upgrade pip
python3.10 -m venv myenv
source myenv/bin/activate
