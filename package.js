Package.describe({
  summary: "Provides basic job queue and task scheduling functionality."
});

Package.on_use(function(api, where) {
  api.use(['coffeescript', 'font-awesome'], ['client', 'server']);
  api.imply('meteor-file', ['client', 'server']); //for upload processor only...
  api.use(['simple-schema', 'npm'], 'server');
  api.use('handlebars', 'client');
  api.add_files('collections.js', ['client', 'server'])
  api.add_files([
    'processors/base/Processor.coffee',
    'monitor.coffee', 
    'pipelines.coffee', 
    'UploadProcessorCallback.coffee', 
    'processors/Md5GenProcessor.coffee', 
    'processors/ThumbnailProcessor.coffee', 
    'processors/TikaProcessor.coffee', 
    'processors/UploadProcessor.coffee', 
    'processors/VideoTranscodeProcessor.coffee'], 
    'server');

  api.export(['Processors', 'JobQueue'], ['client', 'server']);
});

Package.on_test(function (api) {
  api.use(["job-queue", "tinytest", "test-helpers", "coffeescript"]); 
  api.add_files("tests/job-queue-test.coffee", ["client", "server"]);
});
