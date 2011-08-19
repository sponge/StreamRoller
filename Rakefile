desc "Build the app in build/"
task :build do

  sh "mkdir -p build/lib"
  sh "mkdir -p classes"
  sh "javac -d classes -cp src:lib/*:. src/org/streamroller/*.java"

  lib_jars = FileList.new("lib/*.jar")
  classpaths = []
  lib_jars.each do |j|
    sh "cp #{j} build/lib/"
  end

  puts Dir.pwd
  manifest = File.open("Manifest.txt", "w")
  manifest.puts("Main-Class: org.streamroller.Main")
  manifest.puts("Class-Path: #{lib_jars.join(" ")}")
  manifest.close

  sh "jar cfm streamroller.jar Manifest.txt -C classes org/streamroller/"
  sh "mv streamroller.jar build/"
  sh "cp -r src/ build/"

  sh "bundle install --deployment"
  sh "cp -r vendor/ build/"

  sh "cp config.yml.example build/"
  sh "rm Manifest.txt"
  
end

desc "Cleans the build/ directory"
task :clean do
  sh "rm -rf build/*"
end

