#!/bin/bash
## Make a backup of the GHE data, tar it up and copy the snapshot to S3;
## Notify via Slack when done.

## Read configuration file, if it exists
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ ! -f $DIR/.config ]; then
    echo "Script has not been configured yet; did you run make?"
    exit 1
fi
source $DIR/.config

## Import the _send_to_slack function
source $DIR/send-to-slack.sh

## Import the _notify_dms function
source $DIR/notify-dms.sh

## Get the last snapshot ID
CUR_SNAPSHOT_ID=$(readlink ${DATA_DIR}/current)

## Notify DMS at start of backup attempt
_notify_dms

## Run ghe-backup
${UTILS_DIR}/bin/ghe-backup -v 1>>${UTILS_DIR}/backup.log 2>&1

## Get the new snapshot ID
SNAPSHOT_ID=$(readlink ${DATA_DIR}/current)

## Check if the snapshot ID was updated
if [ $CUR_SNAPSHOT_ID == $SNAPSHOT_ID ]; then
    ## Notify of backup failure and exit with status code 1
    _send_to_slack "Backup failed; Snapshot not updated during backup."
    exit 1
fi

## Create a tarball of the snapshot
cd ${DATA_DIR}
tar -czf "${SNAPSHOT_ID}.tar.gz" "${SNAPSHOT_ID}"

## Upload snapshot tarball to S3
aws s3 cp "$SNAPSHOT_ID.tar.gz" s3://${S3_BUCKET}

## Delete the tarball to free up space
rm -rf "$SNAPSHOT_ID.tar.gz"

exit 0
