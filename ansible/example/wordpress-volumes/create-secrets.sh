#!/bin/bash
# usage:
# * modify the second argument of the encode() function calls
# * run "./create-secrets.sh > wordpress-secrets.yaml" to generate the secret file
function encode () {
    echo -n "  $1: " 
    echo -n $2 | base64
}

echo '''apiVersion: v1
kind: Secret
metadata:
  name: wordpress-secrets
type: Opaque
data:'''
# replace the second arguments
encode db-password passworddb1q
encode authkey keyauth2w
encode loggedinkey keyloggedin3e
encode secureauthkey keyauthsecure4r
encode noncekey keynonce5t
encode authsalt saltauth6y
encode secureauthsalt saltauthsecure7u
encode loggedinsalt saltloggedin8i
encode noncesalt saltnonce9o
