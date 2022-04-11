#!/bin/bash
set -e

if [ -z "$TF_VAR_labname" ]; then
  echo "environmentname is unset"
  exit 1
fi

(
  set -x

  az extension add --name storage-preview
  az storage blob service-properties update \
    --account-name "${TF_VAR_labname}materials" \
    --static-website \
    --404-document 404.html \
    --index-document index.html

  cd ../../_excercises/
  pwd
  echo 'add Pod-Service data into hugofiles'

  echo "<h2>IP Addressen</h2>" >> content/_index.md

  AKSNAME="${TF_VAR_labname}aks"

  az aks get-credentials -g ${TF_VAR_labname} -n $AKSNAME

  echo "Get Participant Pods Service IPs"

  kubectl get svc

  printf "<h3>Webssh-Server Loadbalancer IP </h3>" >>  content/_index.md

  printf "<p>" >>  content/_index.md
  kubectl describe svc webssh-server | grep Ingress >>  content/_index.md
  printf "</p>" >>  content/_index.md
  printf "<br/>" >>  content/_index.md

  printf "<h3>Pod-Service Loadbalancer IPs </h3>" >>  content/_index.md

  for ((i = i; i<$TF_VAR_labNumberParticipants; i++)); do
    printf "<h5>Pod $i Service ClusterIP: </h5>" >>  content/_index.md

    printf "<p>" >>  content/_index.md
    kubectl describe svc "participant-pod-$i-service" | grep Ingress >>  content/_index.md
    printf "</p>" >>  content/_index.md

    printf "<p>" >>  content/_index.md
    kubectl describe svc "participant-pod-$i-service" | grep IPs >>  content/_index.md
    printf "</p>" >>  content/_index.md
    printf "<br/>" >>  content/_index.md
  done


  echo 'creating hugo static page'
  mkdir themes && cd themes && git clone https://github.com/matcornic/hugo-theme-learn.git && cd ..
  # TC-380: update clipboards.js to avoid jumping in page on copy-to-clipboard when focus was lost
  curl -sSL https://raw.githubusercontent.com/zenorocha/clipboard.js/master/dist/clipboard.min.js > themes/hugo-theme-learn/static/js/clipboard.min.js

  cp config.toml localZIPgenConfig.toml

  sed -i 's/relativeURLs = "false"/relativeURLs = "true"/g' localZIPgenConfig.toml
  sed -i 's/uglyURLs = "false"/uglyURLs = "true"/g' localZIPgenConfig.toml
  sed -i 's/publishDir = "public"/publishDir = "CPJ"/g' localZIPgenConfig.toml
  sed -i 's/baseURL = "\/"/baseURL = ""/g' localZIPgenConfig.toml
  sed -i 's/HUGO\_BASEURL = "https\:\/\/cloudacademyhugo.z6.web.core.windows.net\/"/HUGO_BASEURL = ""/g' localZIPgenConfig.toml

  cat localZIPgenConfig.toml
  echo ""
  echo "create zip folder"

  sudo hugo --config localZIPgenConfig.toml
  ls CPJ/

  echo "zip pass var is:"
  echo ${ZIPPASS}
  zip -rP ${ZIPPASS} cloud_platform_journey-materials.zip CPJ/
  cp cloud_platform_journey-materials.zip content/_index.files/
  sudo hugo --log -v
  ls public/
  az storage blob upload-batch -d \$web -s ./public --account-name "${TF_VAR_labname}materials"


  status=$?
    [ $status -eq 0 ] && echo "Create Material run successful" || exit $status
)