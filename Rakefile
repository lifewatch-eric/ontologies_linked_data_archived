require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = []
  t.test_files = FileList['test/**/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:models"
  t.test_files = FileList['test/models/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:rack"
  t.test_files = FileList['test/rack/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:serializer"
  t.test_files = FileList['test/serializer/test*.rb']
end

namespace :docker do
  desc "Run tests in parallel using docker"
  task :test do
    services = %w(fourstore redis solr)
    internal_ports = {"fourstore" => 8080, "redis" => 6379, "solr" => 8983}
    forks = 4
    begin
      require_relative 'lib/ontologies_linked_data'

      test_files = FileList['test/**/test*.rb'].shuffle
      test_files_sliced = test_files.each_slice(test_files.length / forks).to_a

      # Start docker containers (serially, docker seems to have problems with concurrency)
      ports = {}
      container_ids = []
      puts "Creating #{forks} infrastructure environments"
      forks.times do |i|
        # Start redis, solr, and 4store
        services.each do |srv|
          started = false
          attempts = 0
          container_id = nil
          until started || attempts > 10
            if container_id
              `docker kill #{container_id}`
              `docker rm #{container_id}`
            end
            container_id = `docker run -t -d -p #{internal_ports[srv]} palexander/#{srv}`.strip
            started = $?.success?
            attempts += 1
          end
          container_ids << container_id
          ports["#{srv}#{i}"] = `docker port #{container_id} #{internal_ports[srv]}`.split(":").last.to_i
        end
      end

      # Let docker start
      sleep(15)

      # Run the tests in forks
      pids = []
      forks.times do |i|
        pids << fork do
          puts "Fork #{i} testing #{test_files_sliced[i].join(", ")}"

          begin
            # redirect stdout
            require 'stringio'
            sio = StringIO.new
            $stdout = sio
            $stderr = sio

            LinkedData.config do |config|
              config.goo_port          = ports["fourstore#{i}"]
              config.goo_redis_port    = ports["redis#{i}"]
              config.http_redis_port   = ports["redis#{i}"]
              config.search_server_url = "http://localhost:#{ports["solr"+i.to_s]}/solr/"
            end

            require_relative "test/test_case"

            # Stop tests from auto-running
            class ::LinkedData::Unit
              @@stop_auto_run = true
            end

            test_files_sliced[i].each {|f| require_relative f}

            MiniTest::Unit.runner.run
          rescue => e
            sio << "\n#{e.message}\n#{e.backtrace.join("\t\n")}"
          ensure
            # reset stdout
            $stdout = STDOUT
            sio.rewind

            puts "", "", "Fork #{i} completed, output:", sio.read, ""
            Kernel.exit! # force the fork to end without running at_exit bindings
          end
        end
      end

      pids.each {|pid| Process.wait(pid)}
    rescue => e
      puts e.message
      puts e.backtrace.join("\n\t")
    ensure
      puts "\n\nStopping docker containers"
      container_ids.each {|id| `docker kill #{id} && docker rm #{id}`} if container_ids
      Kernel.exit! # force the process to quit without minitest's autorun (triggered on at_exit)
    end
  end
end

desc "Run test coverage analysis"
task :coverage do
  puts "Code coverage reports will be visible in the /coverage folder"
  ENV["COVERAGE"] = "true"
  Rake::Task["test"].invoke
end

namespace :data do
  desc "Create sample data"
  task :create do
    require_relative "test/data/generate_test_data"
    LinkedData::TestData::Generate.create
  end

  desc "Remove sample data"
  task :delete do
    require_relative "test/data/generate_test_data"
    LinkedData::TestData::Generate.delete
  end

  desc "Delete all data"
  task :destroy do
    require_relative "test/data/destroy_test_data"
  end

  desc "Console for working with data"
  task :console do
    require_relative "test/data/generate_test_data"
    binding.pry
  end
end

namespace :test do
  if ENV['TESTOPTS']
    if (not (ENV['TESTOPTS'].index "--skip-parsing").nil?)
      test_opts = ENV['TESTOPTS'].dup
      test_opts["--skip-parsing"]=""
      ENV['TESTOPTS'] = test_opts
      ENV['SKIP_PARSING'] = "please" #be nice
    end
  end
end
