module.exports = (grunt) ->
  grunt.file.defaultEncoding = 'utf8'

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    jasmine_node:
      options:
        forceExit: true
        coffee: true
        includeStackTrace: true
      all: ['spec/']

    watch:
      test:
        files: ['lib/*.coffee', 'spec/*.coffee']
        tasks: ['jasmine_node']

  require('load-grunt-tasks')(grunt)
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-jasmine-node-new'

  grunt.registerTask 'default', ['jasmine_node', 'watch']
