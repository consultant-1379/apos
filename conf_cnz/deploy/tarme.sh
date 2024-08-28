#!/bin/bash

function abort(){
  echo "$*" >&2
  exit 1
}

while read object_dir; do
  pushd "$object_dir" &>/dev/null || abort "failure while entering directory $object_dir"
  object="$(basename $object_dir)"
  [[ ! "$object" =~ ((TARME)|(TARGZME))\+(([0-7]{3})?)\+.+$ ]] && abort "unsupported directory found: $object"
  operation="$(echo $object | awk -F'+' '{print $1}')"
  permissions="$(echo $object | awk -F'+' '{print $2}')"
  [ -z "$permissions" ] && permissions=640
  [[ ! "$permissions" =~ ^[0-7]{3}$ ]] && abort "wrong permissions ($permissions) specified"
  filename=$(echo $object | awk -F'+' '{print $3}')
  echo -e "directory:\t$object_dir"
  echo -e "operation:\t$operation"
  echo -e "permissions:\t$permissions"
  echo -e "filename:\t$filename"
  tarball="$(realpath ../$filename)"
  if [ -e "$tarball" ]; then
    rm -f "$tarball" || abort "failure while deleting existing tarball ($tarball)"
  fi
  case $operation in
    TARME)    
      tar --format=gnu --exclude='TARME+*' --exclude='TARGZME+*' -cf $tarball . || abort "failure while creating $tarball"
    ;;
    TARGZME)
      tar --format=gnu --exclude='TARME+*' --exclude='TARGZME+*' -czf $tarball . || abort "failure while creating $tarball"
    ;;
    *)
      abort "unsupported operation: $operation"
    ;;
  esac
  chmod $permissions ../$filename || abort "failure while applying $permissions permissions to file ../$filename"
  popd &>/dev/null || abort "failure while returning to the previous directory"
  echo -e "\n"
done < <(find . -depth \( -name 'TARME+*' -o -name 'TARGZME+*' \) -type d)
