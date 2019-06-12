#!/usr/bin/env bash

LOG_FILE="/tmp/ec2.sh.log"
echo "Logging operations to '$LOG_FILE' ..."

echo "" | tee -a $LOG_FILE # first echo replaces previous log output, other calls append
echo "Welcome to Agile Data Science 2.0 :)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "I will launch an r5.2xlarge instance in the default VPC for you, using a key and security group we will create." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "The utility 'jq' is required for this script to detect the hostname of your ec2 instance ..." | tee -a $LOG_FILE
echo "Detecting 'jq' ..." | tee -a $LOG_FILE
if [ -z `which jq` ]; then
  echo "'jq' was not detected. Installing 'jq' ..." | tee -a $LOG_FILE
  bash ./jq_install.sh
  PROJECT_HOME=`pwd`
  export PATH=$PATH:$PROJECT_HOME/bin
else
  echo "'jq' was detected ..." | tee -a $LOG_FILE
fi

# Can't proceed if jq still not detected
if [ -z `which jq` ]; then
  echo "'jq' was still not detected. We use 'jq' to create the 'agile_data_science' key and to get the external hostname of the ec2 instance we create." | tee -a $LOG_FILE
  echo "Please install jq, or open the script './ec2.sh' and use manually, creating the file './agile_data_science.pem' manually." | tee -a $LOG_FILE
  echo "'jq' install instructions are available at https://github.com/stedolan/jq/wiki/Installation" | tee -a $LOG_FILE
  echo "" | tee -a $LOG_FILE
  echo "Goodbye!" | tee -a $LOG_FILE
  echo "" | tee -a $LOG_FILE
  exit
fi

if [ -z `which aws` ]; then
    echo "You need to install the aws CLI tool. Go here for installation instructions https://aws.amazon.com/cli/" | tee -a $LOG_FILE
    exit
fi

echo "Testing for security group 'agile_data_science' ..." | tee -a $LOG_FILE
GROUP_NAME_FILTER=`aws ec2 describe-security-groups | jq '.SecurityGroups[] | select(.GroupName == "agile_data_science") | length'`

if [ -z "$GROUP_NAME_FILTER" ]
then
  echo "Security group 'agile_data_science' not present ..." | tee -a $LOG_FILE
  echo "Creating security group 'agile_data_science' ..." | tee -a $LOG_FILE
  aws ec2 create-security-group --group-name agile_data_science --description "Security group for the book, Agile Data Science 2.0" | tee -a $LOG_FILE
  SKIP_AUTHORIZE_22=false
else
  echo "Security group 'agile_data_science' already exists, skipping creation ..." | tee -a $LOG_FILE
fi

echo ""
echo "Detecting external IP address ..." | tee -a $LOG_FILE
EXTERNAL_IP=`dig +short myip.opendns.com @resolver1.opendns.com`

if [ "$SKIP_AUTHORIZE_22" == false ]
then
  echo "Skipping authorization of port 22 ..." | tee -a $LOG_FILE
else
  echo "Authorizing port 22 to your external IP ($EXTERNAL_IP) in security group 'agile_data_science' ..." | tee -a $LOG_FILE
  aws ec2 authorize-security-group-ingress --group-name agile_data_science --protocol tcp --cidr $EXTERNAL_IP/32 --port 22
fi

echo ""
echo "Testing for existence of keypair 'agile_data_science' and key 'agile_data_science.pem' ..." | tee -a $LOG_FILE
KEY_PAIR_RESULTS=`aws ec2 describe-key-pairs | jq '.KeyPairs[] | select(.KeyName == "agile_data_science") | length'`

# Remove the old key no matter what - too hard to manage otherwise
if [ \( -n "$KEY_PAIR_RESULTS" \) -a \( -f "./agile_data_science.pem" \) ]
then
  echo "Existing key pair 'agile_data_science' detected, removing ..." | tee -a $LOG_FILE
  rm -f ./agile_data_science.pem
  aws ec2 delete-key-pair --key-name agile_data_science
fi

# Now create a new key no matter what
echo "Generating new keypair called 'agile_data_science' ..." | tee -a $LOG_FILE

aws ec2 create-key-pair --key-name agile_data_science|jq .KeyMaterial|sed -e 's/^"//' -e 's/"$//'| awk '{gsub(/\\n/,"\n")}1' > ./agile_data_science.pem
echo "Changing permissions of 'agile_data_science.pem' to 0600 ..." | tee -a $LOG_FILE
chmod 0600 ./agile_data_science.pem

# Now get the region...
echo "" | tee -a $LOG_FILE
echo "Detecting the default region..." | tee -a $LOG_FILE
DEFAULT_REGION=`aws configure get region`
echo "The default region is '$DEFAULT_REGION'" | tee -a $LOG_FILE

# There are no associative arrays in bash 3 (Mac OS X) :(
# Ubuntu 17.10 hvm:ebs-ssd
# See https://cloud-images.ubuntu.com/locator/ec2/ if this needs fixing
echo "Determining the image ID to use according to region..." | tee -a $LOG_FILE
case $DEFAULT_REGION in
  ap-south-1) UBUNTU_IMAGE_ID=ami-082b19ea285e9cd03
  ;;
  us-east-1) UBUNTU_IMAGE_ID=ami-0a399aac42a48483d
  ;;
  ap-northeast-1) UBUNTU_IMAGE_ID=ami-044384ef1ff500b21
  ;;
  eu-west-1) UBUNTU_IMAGE_ID=ami-061fc58b1cebb1376
  ;;
  ap-southeast-1) UBUNTU_IMAGE_ID=ami-055ce3ce3faaf86b7
  ;;
  us-west-1) UBUNTU_IMAGE_ID=ami-0cfa083fddef879bd
  ;;
  eu-central-1) UBUNTU_IMAGE_ID=ami-0366f703a7edcf070
  ;;
  sa-east-1) UBUNTU_IMAGE_ID=ami-00068b651c5f021bc
  ;;
  ap-southeast-2) UBUNTU_IMAGE_ID=ami-0390e0896ca0fc1e5
  ;;
  ap-northeast-2) UBUNTU_IMAGE_ID=ami-04c2099a34a1ac6f6
  ;;
  us-west-2) UBUNTU_IMAGE_ID=ami-06a6b4750fd1c15b3
  ;;
  us-east-2) UBUNTU_IMAGE_ID=ami-090e94393aedd60f5
  ;;
  eu-west-2) UBUNTU_IMAGE_ID=ami-0a54b4adf39df16b2
  ;;
  ca-central-1) UBUNTU_IMAGE_ID=ami-009ef39e13f1ec001
  ;;
  eu-west-3) UBUNTU_IMAGE_ID=ami-0cc2c05af0e9a4d16
  ;;
  eu-north-1) UBUNTU_IMAGE_ID=ami-1ea12960
  ;;
  ap-northeast-3) UBUNTU_IMAGE_ID=ami-07a20a542c2f6108a
  ;;
esac
echo "The image for region '$DEFAULT_REGION' is '$UBUNTU_IMAGE_ID' ..."

# Launch our instance, which ec2_bootstrap.sh will initialize, store the ReservationId in a file
echo "" | tee -a $LOG_FILE
echo "Initializing EBS optimized r5.2xlarge EC2 instance in region '$DEFAULT_REGION' with security group 'agile_data_science', key name 'agile_data_science' and image id '$UBUNTU_IMAGE_ID' using the script 'aws/ec2_bootstrap.sh'" | tee -a $LOG_FILE
rm -f .reservation_id
aws ec2 run-instances \
    --image-id $UBUNTU_IMAGE_ID \
    --security-groups agile_data_science \
    --key-name agile_data_science \
    --instance-type r5.2xlarge \
    --user-data file://aws/ec2_bootstrap.sh \
    --ebs-optimized \
    --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":true,"VolumeSize":2048}}' \
    --count 1 \
| jq .ReservationId | tr -d '"' > .reservation_id

RESERVATION_ID=`cat ./.reservation_id`
echo "Got reservation ID '$RESERVATION_ID' ..." | tee -a $LOG_FILE

# Use the ReservationId to get the public hostname to ssh to
echo ""
echo "Sleeping 10 seconds before inquiring to get the public hostname of the instance we just created ..." | tee -a $LOG_FILE
sleep 5
echo "..." | tee -a $LOG_FILE
sleep 5
echo "Awake!" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Using the reservation ID to get the public hostname ..." | tee -a $LOG_FILE
INSTANCE_PUBLIC_HOSTNAME=`aws ec2 describe-instances | jq -c ".Reservations[] | select(.ReservationId | contains(\"$RESERVATION_ID\"))| .Instances[0].PublicDnsName" | tr -d '"'`

echo "The public hostname of the instance we just created is '$INSTANCE_PUBLIC_HOSTNAME' ..." | tee -a $LOG_FILE
echo "Writing hostname to '.ec2_hostname' ..." | tee -a $LOG_FILE

rm -f .ec2_hostname
echo $INSTANCE_PUBLIC_HOSTNAME > .ec2_hostname
echo "" | tee -a $LOG_FILE

echo "Now we will tag this ec2 instance and name it 'agile_data_science_ec2' ..." | tee -a $LOG_FILE
INSTANCE_ID=`aws ec2 describe-instances | jq -c ".Reservations[] | select(.ReservationId | contains(\"$RESERVATION_ID\"))| .Instances[0].InstanceId" | tr -d '"'`

if [ ! -z "$INSTANCE_ID" ] # Only run tag if INSTANCE_ID is defined
then
  echo "Got instance id \"$INSTANCE_ID\" ... tagging it ..."
  aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=agile_data_science_ec2
  echo "" | tee -a $LOG_FILE
else
  echo "Got no instance id! Exiting!"
  exit 1
fi

echo "After a few minutes (for it to initialize), you may ssh to this machine via the command in red: " | tee -a $LOG_FILE
# Make the ssh instructions red
RED='\033[0;31m'
NC='\033[0m' # No Color
echo -e "${RED}ssh -i ./agile_data_science.pem ubuntu@$INSTANCE_PUBLIC_HOSTNAME${NC}" | tee -a $LOG_FILE
echo "Note: only your IP of '$EXTERNAL_IP' is authorized to connect to this machine." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "NOTE: IT WILL TAKE SEVERAL MINUTES FOR THIS MACHINE TO INITIALIZE. PLEASE WAIT FIVE MINUTES BEFORE LOGGING IN." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Note: if you ssh to this machine after a few minutes and there is no software in \$HOME, please wait a few minutes for the install to finish." | tee -a $LOG_FILE

echo "" | tee -a $LOG_FILE
echo "Once you ssh in, the exercise code is in the Agile_Data_Code_2 directory! Run all files from this directory, with the exception of the web applications, which you will run from ex. ch08/web" | tee -a $LOG_FILE

echo "" | tee -a $LOG_FILE
echo "Note: after a few minutes, now you will need to run ./ec2_create_tunnel.sh to forward ports 5000 and 8888 on the ec2 instance to your local ports 5000 and 8888. This way you can run the example web applications on the ec2 instance and browse them at http://localhost:5000 and you can view Jupyter notebooks at http://localhost:8888" | tee -a $LOG_FILE
echo "If you tire of the ssh tunnel port forwarding, you may end these connections by executing ./ec2_kill_tunnel.sh" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "---------------------------------------------------------------------------------------------------------------------" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Thanks for trying Agile Data Science 2.0!" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "If you have ANY problems, please file an issue on Github at https://github.com/rjurney/Agile_Data_Code_2/issues and I will resolve them." | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "If you need help creating your own applications, or with on-site or video training..." | tee -a $LOG_FILE
echo "Check out Data Syndrome at http://datasyndrome.com" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Enjoy! Russell Jurney <@rjurney> <russell.jurney@gmail.com> <http://linkedin.com/in/russelljurney>" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
