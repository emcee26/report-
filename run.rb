# File name structure YYYY-MM-DD_Clap_Report_XX.csv.
# Replace the "," to " " in file and save to CURRENT_PATH/data/ folder.
# Delete all TEMPORARY files
# Fill in each details checking csv file.
# Proceed to run further steps.

require 'rubygems'
require 'date'
require 'pry'

class Clap
  def check_file_arg(list)
    unless Dir.exist?("#{$file_path}/data/")
      abort("\n FOLDER 'data' does not exist\n")
    end
    choose_filename
    if File.zero?(@filename)
      abort("\n FILE '#{@filename.split("/").last}' is empty")
    end
  end

  def choose_filename
    f_list = Dir.glob("#{$file_path}/data/#{$run_date}_Clap_Report_*.csv")
    f_cnt = f_list.length
    f_list << "Exit"
    if f_cnt > 1
      seq = 0
      f_list.each do |f_name|
        seq = seq + 1
        print "\n#{seq}: #{f_name.split("/").last}\n"
      end
      print "\n Enter which file :"
      f_num = gets
      if f_list[f_num.to_i-1].nil?
        print "\nWRONG ENTRY\n"
        choose_filename
      elsif f_list[f_num.to_i-1] == "Exit"
        abort("\n THANK YOU \n")
      else
        @filename = f_list[f_num.to_i-1]
      end
    elsif f_cnt == 1
      @filename = f_list.first
    else
      abort("\nNO FILE EXIST\n")
    end
  end

  def initialize
    $file_path = File.expand_path(File.dirname(__FILE__))
    $run_date = (ARGV.empty?) ? (Date.today-1).strftime("%Y-%m-%d") : ARGV[0].to_s
    @filename = ""
    check_file_arg(ARGV)
  end

  def process_line(line)
    c = line.split(",")
    "#{c[0]},#{c[2]},#{c[3]},#{c[6]},#{c[41]},#{c[47]},#{c[49]},#{c[71]},#{c[72]},#{c[73]},#{c[76]},#{c[80]},#{c[82]}\n"
  end

  def wrt_to_file(file_nm,line)
    content = process_line(line)
    File.open("#{file_nm}", 'a+') { |file| file.write(content) }
  end

  def rides(file)
    out_hash = {}
    File.open(file).each.with_index do |line,i|
      next if i == 0
      m = line.split(',')[4].split('/')[1].to_i
      month = Date::MONTHNAMES[m]
      status = line.split(',')[3]
      if out_hash[month]
        if out_hash[month][status]
          out_hash[month][status]+=1
        else
          out_hash[month].merge!({status => 1})
        end
      else
        out_hash[month] = {status => 1}
      end
    end
    return out_hash
  end

  def revenue(file)
    out_hash = {}
    File.open(file).each.with_index do |line,i|
      next if i == 0
      m = line.split(',')[4].split('/')[1].to_i
      month = Date::MONTHNAMES[m]
      status = line.split(',')[3]
      amount = line.split(',')[7].gsub(/[_ ]/,'').to_i
      if out_hash[month]
        if out_hash[month][status]
          out_hash[month][status]+=amount
        else
          out_hash[month].merge!({status => amount})
        end
      else
        out_hash[month] = {status => amount}
      end
    end
    return out_hash
  end

  def driver_agent(file,type)
    out_hash = {"MONTH" => {type.upcase => {"STATUS" => {"BILL" => "COUNT"}}}}
    File.open(file).each.with_index do |line,i|
      next if i == 0
      m = line.split(',')[4].split('/')[1].to_i
      month = Date::MONTHNAMES[m]
      status = line.split(',')[3]
      amount = line.split(',')[7].gsub(/[_ ]/,'').to_i
      driver = line.split(',')[5] if type == 'driver'
      driver = line.split(',')[6] if type == 'agent'
      if out_hash[month]
        if out_hash[month][driver]
          if out_hash[month][driver][status]
            x_amt = out_hash[month][driver][status].keys[0]
            x_cnt = out_hash[month][driver][status][x_amt]
            out_hash[month][driver][status] = {x_amt+amount => x_cnt+1}
          else
            out_hash[month][driver].merge!({status => {amount=>1}})
          end
        else
          out_hash[month].merge!({driver => {status => {amount=>1}}})
        end
      else
        out_hash[month] = {driver => {status => {amount=>1}}}
      end
    end
    return out_hash
  end

  def clap(file)
    out_hash = {"MONTH" => {"RIDE STATUS" => {"BILL" => {"CUST" => {"AFTEXP" => "C  SHARE"}}}}}
    File.open(file).each.with_index do |line,i|
      next if i == 0
      m = line.split(',')[4].split('/')[1].to_i
      month = Date::MONTHNAMES[m]
      status = line.split(',')[3]
      net_bill = line.split(',')[7].gsub(/[_ ]/,'').to_i
      frm_cus = line.split(',')[9].gsub(/[_ ]/,'').to_i
      aft_exp = line.split(',')[10].gsub(/[_ ]/,'').to_i
      c_share = line.split(',')[11].gsub(/[_ ]/,'').to_i

      if out_hash[month]
        if out_hash[month][status]
          x_net_bill = out_hash[month][status].keys[0]
          x_frm_cus = out_hash[month][status][x_net_bill].keys[0]
          x_aft_exp = out_hash[month][status][x_net_bill][x_frm_cus].keys[0]
          x_c_share = out_hash[month][status][x_net_bill][x_frm_cus][x_aft_exp]
          out_hash[month][status] = {(net_bill+x_net_bill)=>{(frm_cus+x_frm_cus)=>{(aft_exp+x_aft_exp)=>(c_share+x_c_share)}}}
        else
          out_hash[month].merge!({status=>{(net_bill)=>{(frm_cus)=>{(aft_exp)=>(c_share)}}}})
        end
      else
        out_hash[month] = ({status=>{(net_bill)=>{(frm_cus)=>{(aft_exp)=>(c_share)}}}})
      end
    end
    return out_hash
  end

  def pending_pay(type,file)
    out_hash = {"MONTH" => {"CUSTOMER" => {"RIDE STATUS" => {"COUNT" => {"BILL" => {"AFTEXP" => "CSHARE"}}}}}}
    out_hash = {"MONTH" => {"STATUS" => {"COUNT" => {"BILL" => {"AFTEXP" => "CSHARE"}}}}} if type == "total"
    File.open(file).each.with_index do |line,i|
      next if i == 0
      m = line.split(',')[4].split('/')[1].to_i
      month = Date::MONTHNAMES[m]
      status = line.split(',')[3]
      collect = line.split(',')[8]
      bill = line.split(',')[7].gsub(/[_ ]/,'').to_i
      aft_exp = line.split(',')[10].gsub(/[_ ]/,'').to_i
      c_share = line.split(',')[11].gsub(/[_ ]/,'').to_i
      customer = line.split(',')[2]
      if collect == "Pending" and type == 'total'
        if out_hash[month]
          if out_hash[month][status]
            x_count = out_hash[month][status].keys[0]
            x_bill = out_hash[month][status][x_count].keys[0]
            x_aft_exp = out_hash[month][status][x_count][x_bill].keys[0]
            x_c_share = out_hash[month][status][x_count][x_bill][x_aft_exp]
            out_hash[month][status] = {(x_count+1)=>{(bill+x_bill)=>{(aft_exp+x_aft_exp)=>(c_share+x_c_share)}}}
          else
            out_hash[month].merge!(status=>{1=>{bill=>{aft_exp=>c_share}}})
          end
        else
          out_hash[month] = {status=>{1=>{bill=>{aft_exp=>c_share}}}}
        end
      elsif collect == "Pending" and type == "customer"
        if out_hash[month]
          if out_hash[month][customer]
            if out_hash[month][customer][status]
              x_count = out_hash[month][customer][status].keys[0]
              x_bill = out_hash[month][customer][status][x_count].keys[0]
              x_aft_exp = out_hash[month][customer][status][x_count][x_bill].keys[0]
              x_c_share = out_hash[month][customer][status][x_count][x_bill][x_aft_exp]
              out_hash[month][customer][status] = {(x_count+1)=>{(bill+x_bill)=>{(aft_exp+x_aft_exp)=>(c_share+x_c_share)}}}
            else
              out_hash[month][customer].merge!({status=>{1=>{bill=>{aft_exp=>c_share}}}})
            end
          else
            out_hash[month].merge!({customer=>{status=>{1=>{bill=>{aft_exp=>c_share}}}}})
          end
        else
          out_hash[month] = {customer=>{status=>{1=>{bill=>{aft_exp=>c_share}}}}}
        end
      end
    end
    return out_hash
  end


  def settlement(file,type)
    out_hash = {"MONTH"=>{"COLLECT" => {"BILL" => {"CUS" => {"AFTEXP" => "C_SHARE"}}}}}
    if type == "agent"
      out_hash = {"MONTH"=>{"AGENT"=>{"COLLECT" => {"BILL" => {"CUS" => {"AFTEXP" => "C_SHARE"}}}}}}
    elsif type == "driver"
      out_hash = {"MONTH"=>{"DRIVER"=>{"COLLECT" => {"BILL" => {"CUS" => {"AFTEXP" => "C_SHARE"}}}}}}
    end
    File.open(file).each.with_index do |line,i|
      next if i == 0
      m = line.split(',')[4].split('/')[1].to_i
      month = Date::MONTHNAMES[m]
      status = line.split(',')[3]
      collect = line.split(',')[8]
      cus = line.split(',')[9].gsub(/[_ ]/,'').to_i
      bill = line.split(',')[7].gsub(/[_ ]/,'').to_i
      aft_exp = line.split(',')[10].gsub(/[_ ]/,'').to_i
      c_share = line.split(',')[11].gsub(/[_ ]/,'').to_i
      stat = line.split(',')[12].chomp
      driver = line.split(',')[5] if type == 'driver'
      driver = line.split(',')[6] if type == 'agent'
      if ['driver','agent'].include? type and stat == 'Pending'
        if out_hash[month]
          if out_hash[month][driver]
            if out_hash[month][driver][collect]
              x_bill = out_hash[month][driver][collect].keys[0]
              x_cus = out_hash[month][driver][collect][x_bill].keys[0]
              x_aft_exp = out_hash[month][driver][collect][x_bill][x_cus].keys[0]
              x_c_share = out_hash[month][driver][collect][x_bill][x_cus][x_aft_exp]
              out_hash[month][driver][collect] = {(bill+x_bill)=>{(cus+x_cus)=>{(aft_exp+x_aft_exp)=>(c_share+x_c_share)}}}
            else
              out_hash[month][driver].merge!({collect=>{bill=>{cus=>{aft_exp=>c_share}}}})
            end
          else
            out_hash[month].merge!({driver=>{collect=>{bill=>{cus=>{aft_exp=>c_share}}}}})
          end
        else
          out_hash[month] = {driver=>{collect=>{bill=>{cus=>{aft_exp=>c_share}}}}}
        end
      elsif stat == 'Pending'
        if out_hash[month]
          if out_hash[month][collect]
            x_bill = out_hash[month][collect].keys[0]
            x_cus = out_hash[month][collect][x_bill].keys[0]
            x_aft_exp = out_hash[month][collect][x_bill][x_cus].keys[0]
            x_c_share = out_hash[month][collect][x_bill][x_cus][x_aft_exp]
            out_hash[month][collect] = {(bill+x_bill)=>{(cus+x_cus)=>{(aft_exp+x_aft_exp)=>(c_share+x_c_share)}}}
          else
            out_hash[month].merge!({collect=>{bill=>{cus=>{aft_exp=>c_share}}}})
          end
        else
          out_hash[month] = {collect=>{bill=>{cus=>{aft_exp=>c_share}}}}
        end
      end
    end
    return out_hash
  end

  def complete_process(f_name)
    out_file = "#{$file_path}/data/#{Time.now.strftime("%Y-%m-%d-%H%M%S")}_output.csv"
    @output = "RIDES\n"
    output_hash = rides(f_name)
    disp_out(output_hash)
    wrt_to_file(out_file,@output)

    @output = "REVENUE\n"
    output_hash = revenue(f_name)
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "DRIVER\n"
    output_hash = driver_agent(f_name,'driver')
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "AGENT\n"
    output_hash = driver_agent(f_name,'agent')
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "CLAP\n"
    output_hash = clap(f_name)
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "PENDING\n"
    output_hash = pending_pay("total",f_name)
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "PENDING CUSTOMER\n"
    output_hash = pending_pay("customer",f_name)
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "SETTLEMENT\n"
    output_hash = settlement(f_name,"total")
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "SETTLEMENT\n"
    output_hash = settlement(f_name,"driver")
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)

    @output = "SETTLEMENT\n"
    output_hash = settlement(f_name,"agent")
    disp_out(output_hash)
    @output.gsub!('\t',',')
    wrt_to_file(out_file,@output)
  end

  def display(option,f_name)
    output_hash = case option
    when "1"
      rides(f_name)
    when "2"
      revenue(f_name)
    when "3"
      driver_agent(f_name,'driver')
    when "4"
      driver_agent(f_name,'agent')
    when "5"
      clap(f_name)
    when "6"
      pending_pay("total",f_name)
    when "7"
      pending_pay("customer",f_name)
    when "8"
      settlement(f_name,"total")
    when "9"
      settlement(f_name,"driver")
    when "10"
      settlement(f_name,"agent")
    when "11"
      complete_process(f_name)
      return 0
    else
      abort("\nTHANK YOU\n")
    end
    @output = ""
    disp_out(output_hash)
    print @output
  end

  def disp_out(output_hash,out=[])
    ele = output_hash.keys
    ele.each do |key|
      out << key
      if output_hash[key].class == Hash
        disp_out(output_hash[key],out)
      else
        x = out.join("\t")
        @output = @output + "#{x}\t#{output_hash[key]}\n"
      end
      out.pop
    end
  end

  def run
    print "\nEnter first data row :"
    head = gets
    print "\nLast data row:"
    tail = gets
    if head.to_i >= tail.to_i
      abort("\n ENTERERED VALUES #{head} and #{tail} NOT GOOD \n")
    end
    temp_file = "#{@filename.split(".").first}_temp.csv"
    if File.exists?(temp_file)
      abort("\n PLEASE DELETE THE TEMP FILE #{temp_file.split("/").last}")
    end

    content = "Sl.no,Customer ID,Name,Ride Status,Start,Driver Name,Agency,Net Billing,Payment Collected by,Collected from Customer,After Expenses,Clap Share,Collection Status\n"
    File.open("#{temp_file}", 'w') { |file| file.write(content) }

    File.open(@filename).each_line.with_index do |line,i|
    binding.pry
      if i  >= tail.to_i
        print "\n TEMPORARY FILE CREATED \n"
        break;
      elsif i + 1 >= head.to_i
        wrt_to_file(temp_file,line)
      end
    end

    c = true

    ##MENU AND PROCESS
    while c do
      print "\n1. No. of rides\n"
      print "2. Total Revenue\n"
      print "3. Driver\n"
      print "4. Agent\n"
      print "5. Clap\n"
      print "6. Total Pending Payments\n"
      print "7. Customer wise Pending Payments\n"
      print "8. Total Cash settlement Pending\n"
      print "9. Diver wise Cash settlement Pending\n"
      print "10. Agent wise Cash settlement Pending\n"
      print "11. Output Report\n"
      print "0. EXIT\n"
      print "\n Enter youp option:"
      option = gets
      option.chomp!
      display(option,temp_file)
      if option == '0'
        c=false
      else
        print "\n PRESS TO CONTINUE !"
        gets
      end
    end
  end
end

obj = Clap.new
obj.run
