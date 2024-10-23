#!/bin/bash

# Create /var/log/nginx directory if not exists
# To workaround deployment on knative due to this issue: https://github.com/knative/serving/issues/2142
mkdir -p /var/log/nginx

echo "`date -uIns` - nginx/run $@"

exec /usr/sbin/nginx -g "daemon off;"
