#Supposed to be Staging 
#-------------------------------


# stager.rb needs RSruby; on OSX
# export R_HOME=/Library/Frameworks/R.framework/Resources 
# gem install rsruby -- --with-R-dir=$R_HOME
# set env, again for os x
ENV["R_HOME"]='/Library/Frameworks/R.framework/Resources'

require_relative "./stager"
require "pathname"
require "csv"

###Settings to be changed...

#Finds all csv files in directory
DUMPS_DIR="/Volumes/NO\ NAME/*.csv"
OLD_DIR=Dir.getwd


# output csv file
OUTPUT_CSV="./master_csv.csv"
# test file
TEST_FILE="./test.csv"




#Run over files and act
def walkover dumps_file_names
  results_dir="results"
  Dir.mkdir results_dir unless Dir.exist? results_dir
  Dir.chdir results_dir
  dumps_file_names.each do |f|
    5.times {puts}
    puts b=((Pathname.new f).basename).to_s
    m=MasterPlotter.new 2010, f
    m.save_png_plot
    m.save_pdf_plot
    m.get_count
  end
  Dir.chdir OLD_DIR
  MasterPlotter.save_csv
end

    
#Call this to run the process
def all
  dumps_file_names=Dir.glob DUMPS_DIR
  #Dir.chdir "/Users/carlobifulco/Dropbox/caHUB/caHubDumps_copy/"
  walkover dumps_file_names
end

# test function
def test file_name=TEST_FILE
  walkover ([]<<file_name)
end