require "pathname"
require "rsruby"
require "csv"

RSRuby.set_default_mode RSRuby::NO_CONVERSION
$r=RSRuby.instance



  
$FIELD_TO_SCAN= "DIAGNOSIS_TEXT"




#ENCOUNTERNUMBER	CORPORATENUMBER	PATIENTNAME	DOB	SEX	CASE_NUMBER	CASE_REPORTING_DATE	SPECIMENTYPE	
#REPORT_SECTION	ORDERING_PROVIDER	REPORT_TAT	RESPONSIBLE_PATHOLOGIST	CASE_STATUS	SIGNED_DT	DIAGNOSIS_TEXT	AGEATOBSERVATION


module CountT
  
  
  def header
    r=[]
    ["PT1","PT2","PT3","PT4"].each do |t|
      r.concat(["","A","B","C","D"].map{|x| t+x})
    end
    r
  end
  
  def count all_t
    #>> r=count(s.get_T s.get_sv)
    r={}
    header.each do |t|
      r[t]=(all_t.count t)
    end
    r
  end
  
  def get_count_array all_t
    (count all_t).values
  end
  
  def count_non_0 all_t
    # >> r=count_non_0(s.get_T s.get_sv)
    (count all_t).select{|k,v| v>0}
  end
  
  def get_T table_array,pattern=/.(T\d)./ #ONLY Ts
    #RSRuby.set_default_mode(RSRuby::VECTOR_CONVERSION)
    #r=RSRuby.instance
    s=[]
    f=[]
    #pattern=/.(T\d)./ #ONLY Ts
    #pattern=/.(T\d.)/ #ALSO As
  
    table_array.each do |row|
      s<<(row[:diagnosis_text].match pattern)[1] if (row[:diagnosis_text].match pattern)
      f<<row if not (row[:diagnosis_text].match pattern)
    end
    puts "#{@title}: tot= #{table_array.length}; found Ts =#{s.length};  failures=#{(f.length)}"
    s=(s.map{|i| abcd(("p"+i.to_s).upcase.strip)})
    #puts s
    s.select!{|i| i if (i[2].to_i>0 and i[2].to_i<5)} #remove T0 and T5...
    #r.assign("s",s)
    #puts r.factor(s,{:order=>"T"})
    #puts r.data_frame(r.table(r.factor(s,{:order=>"T"})))
    #results=r.eval_R("data.frame(table(factor(s)))")
    #puts "#{results['Var1']}, #{results['Freq']}"
    #RSRuby.set_default_mode RSRuby::NO_CONVERSION
    return s
  end
  
  def abcd x
    #pt1z ...
    unless x.length<4
      if "ABCD".include? x[3]
        x
      else
        x=x[0..2]
      end
    end
    x
  end
  
  
end


class Stager
  
  attr_accessor :table, :r, :c, :file_name
  include CountT
  
  def initialize(year,file_name="./test.csv") # 2010 when testing
    years_dir="years"
    Dir.mkdir years_dir unless Dir.exist? years_dir   
    @file_name=file_name
    @year=year
    self.clean_file
    self.get_year
  end
    
  def clean_file
    if File.readable? @file_name
      @c=CSV.read(@file_name,headers:true)
      if @c.headers[-1]==nil
        @c.by_col!
        @c.delete(-1)
        puts "DELETED NIL COLUMN"
      end
     save_c @c.to_a, @file_name
     @c=CSV.table @file_name
    else
        puts "could not find your file"
    end
  end
   
  def get_all
    @c
  end
  
  def get_sv 
    #SP, SV
    @c.select{|row| (row[:case_number].split("-"))[0]=="SV"}
  end
  
  def get_sp
    #SP, SV
    @c.select{|row| (row[:case_number].split("-"))[0]=="SP"}
  end
  
  def get_not_sv_sp
    @c.select{|row| (not ["SV","SP"].member? row[:case_number].split("-")[0])}
  end
  
  def get_year 
    #dump date format "1/3/2006 15:08" OTHER FORMATS GENERATED BY NUMBERS .split()[0].split("/")[-1]
    # NUMBERS "Jun 28, 2010 7:17 PM"  " .split(",")[1].split()[0]
    
    s=@c.select{|row| row[:case_reporting_date].split(",")[1].split()[0]==@year.to_s}
    @c=s
    # c_new=[]<<@c.headers.join(",")
    # c_row=@c.by_row
    # 0.upto(@c.length-1).each do |i|
    #   if (@c[:case_reporting_date][i].split()[0].split("/")[-1]) ==@year.to_s
    #     c_new<<c_row[i].to_s 
    #   end
    #   puts i
    # end
    # 
    # save_c c_new, @new_file_name
    # @c=CSV.table @new_file_name
    # #c_new
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
    new_file_name="#{@year.to_s}_#{(Pathname.new @file_name).basename.to_s}"
    split=new_file_name.split("_")
    "#{split[1].capitalize} Cancer #{split[0]}"
  end
  

end

class Plotter
  
  include CountT
  
  attr_accessor :s,:stage,:summary
  
  def initialize table_array, title
    @title=title
    @table_array=table_array
    @stage=get_T @table_array
    #plot stager_obj.get_T, stager_obj.get_title
  end
  

  
  def count_T
    r=[]
    r<< (@stage.count "PT1")
    r<< (@stage.count "PT2")
    r<< (@stage.count "PT3")
    r<< (@stage.count "PT4")
    r
  end
  
  def plot xlim
    $r.barplot($r.summary($r.factor(@stage,{:order=>"T"})),{:xlim=>[0,xlim],:ylim=>[0,4],:horiz=>"True", :cex_names=>1})
    
    #$r.barplot(get_T,{:horiz=>"True", :cex_names=>1})
    $r.title({:main=>@title,:xlab=>"Cases #",:ylab=>"Stage"})
     
    # $r.factor
    #     $r.barplot(@r.summary(@r.factor(t,order=T)))
    #R.res=t
    #R.eval("barplot(summary(factor(res, order=T)),main='#{title}',ylab='n.cases',xlab='stage')")
  end
end

class SpreadSheet
  include CountT
  attr_accessor :dumps_file_names
  def initialize(new_csv_file_name, year=2010, directory="/Users/carlobifulco/Dropbox/caHUB/caHubDumps_copy")
    results_dir="results"
    Dir.mkdir results_dir unless Dir.exist? results_dir
    @dumps_file_names=Dir.glob File.join(directory,"*.csv")
    @fh=File.open(File.join(results_dir,new_csv_file_name),"w")
    @year=year
  end
   #pattern=/.(T\d)./ #ONLY Ts
    #pattern=/.(T\d.)/ #ALSO As
  def scan regex
    @fh.write (["SITE"].concat header).to_csv
    @dumps_file_names.each do |i|
      puts i
      begin
        s=Stager.new @year,i
        @fh.write (["#{s.get_title} PSV"].concat get_count_array  (get_T s.get_sv, regex)).to_csv
        @fh.write (["#{s.get_title} PPMC"].concat get_count_array  (get_T s.get_sp, regex)).to_csv
        @fh.write (["#{s.get_title} Other Sites"].concat get_count_array  (get_T s.get_not_sv_sp,regex)).to_csv
        10.times {puts}
      rescue
        puts "ERROR #{i}"
      end
    end
    @fh.close
  end
end


class MasterPlotter
  
  @@output_table=([]<<["C","pT1","pT2","pT3","pT4"])
  @@csv_file_name="~/test.csv"
  
  attr_accessor :s,:graphs, :xlim, :output_table

  def initialize (year,file_name="./test.csv",graph_name=nil)#(file_name="./subset_prostate_dump_prostatectomy_only.csv")
    @graph_name=graph_name
    @file_name=file_name
    @s=Stager.new(year,@file_name)
    $r.par({:mfrow=>[4,1]})
    $r.par({:las=>2}) 
    $r.par({:mar=>[5,8,4,2]})
    @graphs=[]
    #@output_table=[]
    #@output_table<<["C","pT1","pT2","pT3","pT4"]
    self.load_graphs
   

   
  end
  
  def output_table
    @@output_table
  end
  
  def get_xlim
    @xlim=[]
    @graphs.each do |g|
      puts g.stage
      @xlim<<[g.stage.select{|x| x=="PT1"}.length,
        g.stage.select{|x| x=="PT2"}.length,
        g.stage.select{|x| x=="PT3"}.length,
        g.stage.select{|x| x=="PT4"}.length].max
    end
    @xlim.max
  end
  
  def load_graphs
    if not @graph_name
      @graphs<<g1=(Plotter.new @s.get_all,"#{@s.get_title} PSA")
      @graphs<<g2=(Plotter.new @s.get_sv, "#{@s.get_title} PSV")
      @graphs<<g3=(Plotter.new @s.get_sp,"#{@s.get_title} PPMC")
      @graphs<<g4=(Plotter.new @s.get_not_sv_sp, "#{@s.get_title} Not PSV-PPMC")
    else
      @graphs<<g1=(Plotter.new @s.get_all,"#{@graph_name} PSA")
      @graphs<<g2=(Plotter.new @s.get_sv, "#{@graph_name} PSV")
      @graphs<<g3=(Plotter.new @s.get_sp,"#{@graph_name} PPMC")
      @graphs<<g4=(Plotter.new @s.get_not_sv_sp, "#{@graph_name} Not PSV-PPMC")
    end
  end
  
  def get_count 
    #appends Ts to table
    r=graphs[0].count_T
    r.insert 0,(@s.get_title.split.join "_")+".csv"
    @@output_table<<r
    
    # puts @s.get_all
    # puts (@s.get_all).insert(0,@s.new_file_name)
    # @output_table<<((@s.get_all).insert(0,@s.new_file_name))
  end
  
  def MasterPlotter.save_csv
    puts @@csv_file_name
    #CSV.open(@@csv_file_name,"w") do |csv|
    CSV.open(OUTPUT_CSV,"w") do |csv|
     @@output_table.each do |r| 
        csv << r
      end
    end
  end
  
  
  def show_plot
    @graphs.each do |g|
      begin
        g.plot self.get_xlim
      rescue
      end
    end
  end
  
  def save_png_plot  
    pdf_file_name=(@s.get_title.split.join "_")+".png"
    #puts pdf_file_name
    # width = 480, height = 480, units = "px",
    $r.png({:file=>"#{pdf_file_name}",:width=>800,:height=>800,:pointsize=>18})
     #$r.png({:file=>"#{pdf_file_name}",:width=>7.54,:height=>7.54,:pointsize=>18,:units=>"in"})
    $r.par({:mfrow=>[4,1]})
    $r.par({:las=>2}) 
    $r.par({:mar=>[5,8,4,2]})
    @graphs.each do |g|
       g.plot self.get_xlim
    end
    $r.dev_off.call
    #self.show_plot
    # R.eval("pdf(file=file_name)")
    # R.eval("plot(plot_data)")
    # R.eval("dev.off()")
  end
  
  def save_pdf_plot pdf_file_name=nil
    
    pdf_file_name=(@s.get_title.split.join "_")+".pdf" unless pdf_file_name
    puts Dir.getwd+" "+pdf_file_name
    # width = 480, height = 480, units = "px",
    $r.pdf({:file=>"#{pdf_file_name}",:paper=>"letter"})
    $r.par({:mfrow=>[4,1]})
    $r.par({:las=>2}) 
    $r.par({:mar=>[5,8,4,2]})
    @graphs.each do |g|
       g.plot self.get_xlim
    end
    $r.dev_off.call
    #self.show_plot
    # R.eval("pdf(file=file_name)")
    # R.eval("plot(plot_data)")
    # R.eval("dev.off()")
  end
end
