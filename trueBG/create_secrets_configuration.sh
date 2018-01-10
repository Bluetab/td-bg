#!/bin/bash
sed -i -e "s/password:.*,/password: \"$DB_PASSWORD\",/g" ./config/prod.secret.exs
sed -i -e "s/hostname:.*,/hostname: \"$DB_HOST\",/g" ./config/prod.secret.exs
sed -i -e "s/bucket:.*/bucket: \"$AWS_S3_BUCKET\"/g" ./config/prod.secret.exs
sed -i -e "s/access_key_id:.*,/access_key_id: \"$AWS_ACCESS_KEY_ID\",/g" ./config/prod.secret.exs
sed -i -e "s/secret_access_key:.*/secret_access_key: \"$AWS_SECRET_ACCESS_KEY\"/g" ./config/prod.secret.exs
cp ./config/prod.secret.exs ~/fasttag.prod.secret.exs
