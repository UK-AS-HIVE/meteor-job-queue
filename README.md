meteor-job-queue
================

Process batched jobs across a cluster of Meteor web and compute nodes.
Given a shared Mongo server and a shared file system, this enables construction
and processing of scalable cloud computation for long-running processes such as:

* video transcoding
* metadata extraction and indexing
* thumbnail generation

It also offers potential for geodistributing nodes for reduced endpoint latency (CDN).

To demo proof of concept:

In terminal 1, start the web node:

    git clone git://github.com/UK-AS-HIVE/meteor-job-queue.git
    cd meteor-job-queue
    mkdir uploads
    mrt bundle mjq.tar.gz
    mrt

In terminal 2, extract the bundled version into another directory, and start a compute node
connecting to the same Mongo server:

    pushd .
    cd meteor-job-queue
    export MONGO_URL=`meteor mongo --url`
    popd
    
    mkdir mjq
    mv meteor-job-queue/mjq.tar.gz mjq
    cd mjq
    ln -s ../meteor-job-queue/uploads bundle/programs/server/uploads
    tar xzvf mjq.tar.gz
    HOSTNAME=`hostname` PORT=4001 MONGO_OPLOG_URL=${MONGO_URL} node bundle/main.js

