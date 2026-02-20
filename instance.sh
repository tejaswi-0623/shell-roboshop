#!bin/bash

sg_id="sg-09de3392916ee8cce"
ami_id="ami-0220d79f3f480ecf5"
zone_id="Z08829441IZSXZL32T650" #domain hosted zone id
domain_name="jarugula.online"

for instance in $@ #can create instances from command line i.e, during runtime and instance is vairable here
do
  instance_id=$(aws ec2 run-instances \
        --image-id $ami_id \
        --instance-type "t3.micro" \
        --security-group-ids $sg_id \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text )
#giving the above whole command like output of vairable variable=$(command) to create instance
#the instance is created and we are keeping that instance id in instance_id vairable

  if [ $instance == "frontend" ]; then
    IP_address=$(aws ec2 describe-instances \
               --instance-ids $instance_id \
               --query 'Reservations[].Instances[].PublicIpAddress' \
               --output text)
     record_name="$domain_name" #will create as jarugula.online
  else
     IP_address=$(aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text)
     record_name="$instance.$domain_name" # instancename.daws88s.online
  fi
    echo "Ip address is....$IP_address"
#we are getting ip addresses of instance to create route 53 records 
#if instance created is frontend we need public ip otherwise we need private ip
#IP_address and record_name are vairables here


   aws route53 change-resource-record-sets \
    --hosted-zone-id $zone_id \
    --change-batch "{ 
        "Comment": "Updating record", 
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$record_name'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP_address'"
                }
                ]
            }
            }
        ]
    }
    "
      echo "record updated for $instance"
done

#above command is for creating route 53 records for instances and update  the records with ip addresses
   