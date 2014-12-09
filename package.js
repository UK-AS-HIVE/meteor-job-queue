Package.describe({
  summary: "Provides basic job queue and task scheduling functionality.",
  name: "hive:job-queue",
  git: "https://github.com/UK-AS-HIVE/meteor-job-queue"
});

Npm.depends({
  "imagemagick": "0.1.3"
});

Package.onUse(function(api, where) {
  api.versionsFrom("METEOR@0.9.4");
  api.use(['meteor-platform', 'coffeescript', 'underscore'], ['client', 'server']);
  //api.use('adeshpandey:meteor-file', ['client', 'server']); //for upload processor only...
  api.use(['aldeed:simple-schema@1.0.3'], ['client', 'server']);
  api.use(['spacebars', 'ui'], 'client');
  api.addFiles(['collections.js'], ['client', 'server'])
  api.addFiles([
    'processors/base/Processor.coffee',
    'monitor.coffee', 
    'pipelines.coffee', 
    'processors/Md5GenProcessor.coffee', 
    'processors/ThumbnailProcessor.coffee', 
    'processors/TikaProcessor.coffee', 
    'processors/VideoTranscodeProcessor.coffee'], 
    'server');

  api.export(['Processors', 'JobQueue', 'Scheduler'], ['client', 'server']);
});

Package.onTest(function (api) {
  api.use(["job-queue", "tinytest", "test-helpers", "coffeescript"]); 
  api.addFiles("tests/job-queue-test.coffee", ["client", "server"]);
});
