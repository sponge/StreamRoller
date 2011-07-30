desc "Build the app in build/"
task :build do

  sh "mkdir -p build/lib"
  sh "javac -d classes -cp src:lib/java/*:. src/org/streamroller/*.java"

  lib_jars = FileList.new("lib/java/*.jar")
  classpaths = []
  lib_jars.each do |j|
    sh "cp #{j} build/lib/"
    classpaths << "lib/#{File.basename(j)}"
  end

  puts Dir.pwd
  manifest = File.open("Manifest.txt", "w")
  manifest.puts("Main-Class: org.streamroller.Main")
  manifest.puts("Class-Path: #{classpaths.join(" ")}")
  manifest.close

  sh "jar cfm streamroller.jar Manifest.txt -C classes org/streamroller/"
  sh "mv streamroller.jar build/"
  sh "rm Manifest.txt"
  
end

desc "Cleans the build/ directory"
task :clean do
  sh "rm -rf build/*"
end

