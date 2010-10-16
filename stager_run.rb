require_relative "./stager"
require "pathname"
require "csv"

DUMPS_DIR="/Users/carlobifulco/Dropbox/caHUB/caHubDumps_copy/*.csv"
OLD_DIR=Dir.getwd
dumps_file_names=Dir.glob DUMPS_DIR





def walkover dumps_file_names
  Dir.chdir "/Users/carlobifulco/Dropbox/caHUB/caHubDumps_copy/"
  dumps_file_names.each do |f|
    5.times {puts}
    puts b=((Pathname.new f).basename).to_s
    m=MasterPlotter.new 2009, f
    begin
      m.save_pdf_plot
    rescue
    end
    begin
      m.save_png_plot
    rescue
    end
    m.get_count
  end
  MasterPlotter.save_csv
  Dir.chdir OLD_DIR
end

    

def all
  dumps_file_names=Dir.glob DUMPS_DIR
  Dir.chdir "/Users/carlobifulco/Dropbox/caHUB/caHubDumps_copy/"
  walkover dumps_file_names
  Dir.chdir OLD_DIR
end


def test file_name="/Users/carlobifulco/Dropbox/caHUB/caHubDumps_copy/breast1_carcinoma_caHub_dump_1.csv"
  walkover ([]<<file_name)
  Dir.chdir OLD_DIR
  
end