#!/bin/bash

# Copyright (c) 2019 Wind River Systems Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

copy2s3() {
    local NAME="$1"

    # Use default S3 bucket if one has not been specified
    if [ -z "$S3_BUCKET" ]; then
        echo "INFO: S3_BUCKET not defined. Using default one: s3-build-images."
        S3_BUCKET=s3-build-images
    fi

    if [ -z "$NAME" ]; then
        echo "Error: Rsync post process script requires NAME defined!"
        exit 0
    else
	TIMESTAMP=$(date +%Y%m%d_%H%M)
	# log files and images will be stored into s3://${S3_BUCKET}/${S3_BUCKET_DIR}
	S3_BUCKET_DIR="${TIMESTAMP}-${NAME}"
    fi

    if [ -z "$NFS_ROOT" ]; then
        echo "INFO: NFS_ROOT not defined. Using default one: /opt/rsync."
        NFS_ROOT=/opt/rsync
    fi

    # Check necessary parameters
    if [ -z "$RSYNC_DEST_DIR" ]; then
        echo "Error: copy2s3 script requires RSYNC_DEST_DIR defined!"
        exit 0
    fi

    LOCAL_RSYNC_DIR="$NFS_ROOT/$RSYNC_DEST_DIR"

    AWSCLI="docker run governmentpaas/awscli aws"

    # Copy log files and images to S3
    search_files="-name *Image \
	       -o -name *.tar.bz2 \
	       -o -name *.log \
	       -o -name local.conf"
    echo "LOCAL_RSYNC_DIR=$LOCAL_RSYNC_DIR"
    find "$LOCAL_RSYNC_DIR" -name *Image
    find "$LOCAL_RSYNC_DIR" \( $search_files \) -exec "$AWSCLI" s3 cp {} s3://${S3_BUCKET}/${S3_BUCKET_DIR}/ \;
    "$AWSCLI" aws s3 ls --recursive s3://${S3_BUCKET}/${S3_BUCKET_DIR}
}

copy2s3 "$@"

exit 0
