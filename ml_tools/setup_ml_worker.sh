set -e
exit (1) # Currently this script needs copying and pasting

PROJECT=coda-dev-229611

# Create instance
gcloud compute --project=$PROJECT instances create coda-ml --zone=us-east1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=951917536160-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --image=ubuntu-1804-bionic-v20190212a --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=coda-ml

# Tested on Ubuntu 18.04 LTS

sudo apt update
sudo apt install -y python3-pip python3-dev
pip3 install --user pipenv
echo "PATH=$HOME/.local/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
mkdir GitRepos
cd GitRepos/
git clone https://github.com/AfricasVoices/CodaV2.git
cd CodaV2/
pipenv update
mkdir ~/CryptoTokens

# Copy the crypto token in

screen -DR ml_runner
cd ~/GitRepos/CodaV2/ml_tools
pipenv shell
pip install firebase_admin


python3 -c 'import nltk; nltk.download("stopwords"); nltk.download("punkt");'

python predict_label_pubsub.py 
