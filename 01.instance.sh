#!bin/bash

sg_id="sg-09de3392916ee8cce"
ami_id="ami-0220d79f3f480ecf5"
zone_id="Z08829441IZSXZL32T650"
domain_name="jarugula.online"

for instance in $@ #can create instances from command line ie during runtime
do
  instance_id=$(aws ec2 run-instances \
        --image-id $ami_id \
        --instance-type "t3.micro" \
        --security-group-ids $sg_id \
        --tags-specifications "ResourceType=instance,Tags=[{key=Name,value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)
#giving the above whole command like output of vairable variable=$(command) to create instance
#the instance is created and we are keeping that instance id in instance_id vairable

  if [ $instance=="frontend" ]; then
    IP_address=$(aws ec2 describe-instances \
               --instance-ids $instance_id \
               --query 'Reservations[].Instances[].PublicIpAddress' \
               --output text)
     record_name="$domain_name" #will create as jarugula.online
  else
     IP_address=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text)
     record_name="$instance.$DOMAIN_NAME" # instancename.daws88s.online
  fi
    echo "Ip address is....$IP_address"
#we are getting ip addresses of instance to create route 53 records 
#if instance created is frontend we need public ip otherwise we need private ip


  aws route53 change-resource-record-sets \
    --hosted-zone-id $zone_id \
    --change-batch '
     {
        "Comment": "Updating record", #
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
    '
      echo "record updated for $instance"
done

#above command is for creating route 53 records for instances and update  the records with ip addresses
   