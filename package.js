Package.describe({
  summary: "Provides basic job queue and task scheduling functionality."
});

Package.on_use(function(api) {
  api.use('coffeescript', ['client', 'server']);
  //api.use('spacebars', 'client');
  api.add_files(['server/monitor.coffee', 'server/pipelines.coffee', 'server/server.coffee', 'server/server_save_file.coffee','server/processors/Md5GenProcessor.coffee', 'server/processors/ThumbnailProcessor.coffee', 'server/processors/TikaProcessor.coffee', 'server/processors/UploadProcessor.coffee', 'server/processors/VideoTranscodeProcessor.coffee', 'server/processors/base/Processor.coffee'], 'server');
  api.add_files(['client/client.coffee', 'client/dragndropupload.coffee'], 'client');

  api.export(['JobQueue', 'Processors'], ['client', 'server']);
});

Package.on_test(function (api) {
  api.use(["meteor-job-queue", "tinytest", "test-helpers"]);
  api.add_files("job-queue-test.coffee", ["client", "server"]);
});
