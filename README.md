meteor-job-queue
================

A package for processing batched jobs across a cluster of Meteor web and compute nodes.
This enables construction and processing of scalable server-side computation for long-running
processes such as:

* video transcoding
* metadata extraction and indexing
* thumbnail generation
* indexing a file system
* mirroring content from a feed

Combined with Meteor's rapid prototyping abilities, this framework should enhance rapid development
of apps focusing on user interfaces and web standards.  In other words, it aims to take some of the
burden off of frontend developers who just want to make a fully featured web app.

The package offers:

1. Processor - a Model for a discrete piece of work that needs to be done
2. Scheduler - utilities for adding jobs to the queue
3. Pipelines - contract for defining dependencies and validation on tasks

It also comes with a few built-in processors, focusing on common multimedia and file management
requirements.

Web and Compute Nodes
---------------------
...

Future Work
-----------
...
