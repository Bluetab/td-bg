#!/bin/bash
sed -i -e "s/password:.*,/password: \"$DB_PASSWORD\",/g" ./trueBG/config/prod.secret.exs
sed -i -e "s/hostname:.*,/hostname: \"$DB_HOST\",/g" ./trueBG/config/prod.secret.exs
sed -i -e "s/bucket:.*/bucket: \"$AWS_S3_BUCKET\"/g" ./trueBG/config/prod.secret.exs
sed -i -e "s/access_key_id:.*,/access_key_id: \"$AWS_ACCESS_KEY_ID\",/g" ./trueBG/config/prod.secret.exs
sed -i -e "s/secret_access_key:.*/secret_access_key: \"$AWS_SECRET_ACCESS_KEY\"/g" ./trueBG/config/prod.secret.exs
cp ./trueBG/config/prod.secret.exs ~/truebg.prod.secret.exs
