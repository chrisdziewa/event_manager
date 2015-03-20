require "csv"
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
    legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename, "w") do |file|
        file.puts form_letter
    end
end

def save_mobile_contacts(mobile_template)
    Dir.mkdir("reports") unless Dir.exists? "reports"

    filename = "reports/mobile_alerts.html"

    File.open(filename, "w") do |file|
        file.puts mobile_template
    end
end

def save_hours_report(reg_hours_template)
    Dir.mkdir("reports") unless Dir.exists? "reports"

    filename = "reports/registration-hours.html"

    File.open(filename, "w") do |file|
        file.puts reg_hours_template
    end
end

def clean_phone_number(phone_number)
    phone_number = phone_number.split(/[^0-9]/).join("")
    length = phone_number.length
    if length< 10 || phone_number.nil? || length > 11
        return "bad number"
    elsif length == 11 && phone_number[0] != "1"
        return "bad number"
    elsif length == 11 && phone_number[0] == "1"
        return  phone_number[1..11]
    else
        return phone_number
    end
end

def format_date_time(date_time)
    register_hour = DateTime.strptime(date_time, '%m/%d/%y %H:%M')
end

def get_most_popular_key(hours_hash)
    hours_hash.max_by{|k,v| v}[0]
end

def get_day_name(date)
    Date::DAYNAMES[date.wday]
end

puts "Event Manager Initialized!"

# Thank you template
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

# mobile alerts file
mobile_alerts = File.read "mobile_alerts.erb"
mobile_template = ERB.new mobile_alerts
mobile_list = []

# track hours of registration for report
hours_tracker = {}
(0..24).each  { | hour | hours_tracker[hour] = 0 }

#track days that participants registered on
reg_days_tracker = {}
Date::DAYNAMES.each do |day|
    reg_days_tracker[day] = 0
end

#registration hour report template
reg_hours = File.read "reg_hour_reports.erb"
reg_hours_template = ERB.new reg_hours

## Iterate through attendees
contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)
contents.each do | row |
    id = row[0]
    name = row[:first_name]
    last_name = row[:last_name]
    phone = row[:homephone]

    # Get dates and times and convert to DateTime
    formatted_date_time = format_date_time(row[:regdate])
    register_hour = formatted_date_time.hour

    # add a tally to current our in hours_tracker
    hours_tracker[register_hour]  +=  1

    # find legislators in the area of valid zipcodes
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    # Build thank you letters
    form_letter = erb_template.result(binding)
    save_thank_you_letters(id, form_letter)

    # track registration day frequencies
    day = get_day_name(formatted_date_time)
    reg_days_tracker[day] += 1


    if clean_phone_number(phone) != "bad number"
        mobile_list.push([last_name, name , clean_phone_number(phone)])
    end
end

popular_day = get_most_popular_key(reg_days_tracker)

# Hours with most signups
popular_hour = get_most_popular_key(hours_tracker)

# Create hour report webpage
completed_hours_report = reg_hours_template.result(binding)
save_hours_report(completed_hours_report)

# Create a webpage for valid mobile contacts
completed_mobile_list = mobile_template.result(binding)
save_mobile_contacts(completed_mobile_list)





