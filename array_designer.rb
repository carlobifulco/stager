
require 'rinruby'
require "pathname"
require 'prawn' 
require 'stringio'
require "rsruby"


if RUBY_VERSION > "1.9"    
 require "csv"  
 unless defined? FCSV
   class Object  
     FCSV = CSV 
     alias_method :FCSV, :CSV
   end  
 end
else
 require "fastercsv"
end

begin 
  $FILENAME=ARGV[0]
rescue
  puts "I NEED A CSV FILE NAME!!!"
  
$FIELD_TO_SCAN= "DIAGNOSIS_TEXT"


puts "no deletes row; yes approves"

#ENCOUNTERNUMBER	CORPORATENUMBER	PATIENTNAME	DOB	SEX	CASE_NUMBER	CASE_REPORTING_DATE	SPECIMENTYPE	
#REPORT_SECTION	ORDERING_PROVIDER	REPORT_TAT	RESPONSIBLE_PATHOLOGIST	CASE_STATUS	SIGNED_DT	DIAGNOSIS_TEXT	AGEATOBSERVATION

def para text
  a=text.split
  f=[]

  a.each do |x|
      f << x
      if (f.join(" ").split "\n")[-1].length/7 > 8
      
      
        f<< "\n"
      elsif x.index "*"
        f<< "\n"
      end
  end
  f.join " "
end



class Stager
  
  attr_accessor :table, :r, :c
  
  def initialize(file_name="./subset_prostate_dump_prostatectomy_only.csv")
    @file_name=file_name
    if File.readable? @file_name
      @c=CSV.read(@file_name,headers:true)
      if @c.headers[-1]==nil
        clean_c 
        @c=CSV.table @file_name
      end
    else
      puts "could not find your file"
    end
  end
  
  
  def get_site site_initials
    #SP, SV
    @c.select{|row| (row["CASE_NUMBER"].split("-"))[0]==site_initials}
  end
  
  def get_not_sv_sp
    @c.select{|row| (not ["SV","SP"].member? row["CASE_NUMBER"].split("-")[0])}
  end
  
  def subset parameter, method
    #q=s.c.select {|row| row["REPORT_TAT"].to_f <4}
    
    pos=@c.headers.index parameter
    c_new=CSV.generate do |csv|
      0.upto(@c.length-1).each do |i|
        if method(c[parameter][i])
          c_new<<c[i]
        end
      end
    end
    c_new
  end
  
  def get_year year
    #dump date format "1/3/2006 15:08"
    c_new=[]<<@c.headers.join(",")
    c_row=@c.by_row
    0.upto(@c.length-1).each do |i|
      if (@c["CASE_REPORTING_DATE"][i].split()[0].split("/")[-1]) ==year.to_s
        c_new<<c_row[i].to_s 
      end
      puts i
    end
    @new_file_name="#{year}_#{(Pathname.new @file_name).basename.to_s}"
    save_c c_new, @new_file_name
    @c=CSV.table @new_file_name
    #c_new
  end

  
  
  def clean_c
    @c.by_col!
    @c.delete(-1)
    save_c @c.to_a, @file_name
  end
  
  def save_c c_array, file_name
   
    CSV.open(file_name,"w") do |csv|
      c_array.each do |row|
        row=(CSV.parse_line row) if row.class==String
        csv<<row
      end
    end 
  end
  
  def get_title
    split=@new_file_name.split("_")
    "#{split[1].capitalize} #{split[0]}"
  end
  
  def get_T 
    @r=[]
    @f=[]
    pattern=/.(T\d.)/
    
    @c["DIAGNOSIS_TEXT"].each do |d|
      @r<<(d.match pattern)[1] if (d.match pattern)
      @f<<d if not (d.match pattern)
    end
    puts "Tot= #{@c[-1].length}; found Ts =#{@r.length};  failures=#{(@f.length)}"
    @r=r.map{|i| "p"+i.to_s}
  end
end

class Plotter
  
  def initialize stager_obj
    @r=r=RSRuby.instance
    #plot stager_obj.get_T, stager_obj.get_title
  end
  
  def plot t, title
    @r.barplot(@r.summary(@r.factor(t,order=T)))
    #R.res=t
    #R.eval("barplot(summary(factor(res, order=T)),main='#{title}',ylab='n.cases',xlab='stage')")
  end

end
class ArrayDesigner
  
  # size [number of rows,number of columns]
  attr_reader :n_array_rows,:n_array_cols,:array_data
  def initialize(n_array_rows,n_array_cols, array_data)
    @n_array_rows,@n_array_cols=n_array_rows,n_array_cols
  end
  
  def circles
    
  end
  
  def text
    
  end
  
  def tables
    
  end
  
end



def make_rows_headers
  header=[0]
  (%w"a b c d e f".each {|x| x.capitalize!}).each do |x|
    (1..4).each do |n|
    header << "#{x}#{n}"
    puts header
    end
  end
  return header
end



module CsvMethods
  
  def load_csv filename
    csv_handle=CSV.open(filename)
    header=csv_handle.readline
    return header, csv_handle
  end
  
  def get_headers_positions(eliminate, header)
   eliminate_positions=[]
    eliminate.each do |elim|
      eliminate_positions<<header.index(elim)
    end
    eliminate_positions
  end
  

  def anonymize (header_csv_handle)
    # header list and csv
    header=header_csv_handle[0]
    csv_handle=header_csv_handle[1]
    new_lines=[]
    eliminate=["ENCOUNTERNUMBER","CORPORATENUMBER","PATIENTNAME","DOB","CASE_REPORTING_DATE",
      "REPORT_SECTION", "ORDERING_PROVIDER","REPORT_TAT", "RESPONSIBLE_PATHOLOGIST",
      "CASE_STATUS","SIGNED_DT"]
    eliminate_positions=get_headers_positions(eliminate,header)
    lines=csv_handle.readlines()
    lines.each do |line|
        new_line=line.collect {|field| field if not (eliminate_positions.include?(line.index(field)))}.compact
        puts new_line
        puts line.length
        new_lines<<new_line
    end
    eliminate.each do |e|
      header.delete(e)
    end
    
    new_cvs=[(header.join(","))].concat new_lines
    new_cvs
    
    # a.collect {|x| x if ([1,0,4].include?(a.index(x)))}.compact
    
    
    # eliminate.each do |e|
    #   header.eliminate e
    # end
    # do |line|
    #   eliminate_positions.each do |position|
    #     line.delete_if (position)
    #     new_lines<<line
    #   end
    # 
    # end
    # new_cvs+=header
    # new_cvs+=new_lines
    # return header, new_lines,eliminate
  end
  
  def run filename
    write_file (screen_by_diagnosis(load_csv filename))  
  end
  
  def screen_by_diagnosis (header, csv_handle)
    100.times {puts "\n"}
    new_file=[]<<header
    all=csv_handle.readlines()
    all.each do |line|
     puts para line[POSITION]
     puts "\n"
     puts "yes or no"
     answer=STDIN.readline
     case answer
      when "yes\n"
        puts "YES"
        new_file<<line
      when "no\n"
        puts "NO"
      else
        puts "COULD NOT FIND IT #{answer}"
      end
    100.times {puts "\n"}
    end 
    all
  end

  def write_file line_array
    fh=CSV(File.open FILENAME, "w+")
    line_array.each do |line|
    fh.puts line
    end
    fh.close
  end
end
end

class ArrayDesigner
  include CsvMethods
  
  attr_accessor :cvs, :file_name
  
  def initialize(file_name="./subset_prostate_dump_prostatectomy_only.csv")
        @header,@csv_handle=load_csv file_name
        @cvs=anonymize([@header,@csv_handle])
        @file_name=file_name      
  end
  
  def add_row_label 
    new_cvs=[]
    make_rows_headers.each_with_index do |x,i|
      if i==0
        new_cvs<<(","+(@cvs[i])).split(",")
        next
      end
      new_cvs<<([x]+@cvs[i])
    end
    @cvs=new_cvs
  end
  
  def write_file
    new_file_name="anon_"+(Pathname.new @file_name).basename.to_s
    CSV.open(new_file_name,"w") do |csv|
      @cvs.each do |line|
        csv<<line
      end
    end
  end
  
  def show_file
    Prawn::Document.generate("test.pdf", :page_layout=>:landscape) do 
      t= CSV.read(@file_name,headers: true,header_converters: :symbol)
      headers=t.headers
      entries=t.entries
      table entries, :headers=>headers, font_size=>10,:position=>center
    end
  end

  
end
