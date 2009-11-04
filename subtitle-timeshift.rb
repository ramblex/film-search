# This script timeshifts a .srt file
# USAGE: ruby subtitle-timeshift.rb [SUBTITILE FILE] [SHIFT IN SECONDS]
# Output is put on stdout and can therefore, be redirected.

def change_sub_time(parts, shift)
  mid_part = parts[2].split(",")

  start_ms = mid_part[1].split("-->")[0].strip!.to_i
  end_hours = mid_part[1].split("-->")[1].strip!

  end_part = parts[4].split(",")
  end_ms = end_part[1].to_i

  # Convert times into seconds to make adding the timeshift easy
  start_time = parts[0].to_i * 60 * 60 + parts[1].to_i * 60 + mid_part[0].to_i
  start_time += shift
  end_time = end_hours.to_i * 60 * 60 + parts[3].to_i * 60 + end_part[0].to_i
  end_time += shift

  # Convert the timestamps back into format
  start_hours = start_time / 3600
  start_mins = start_time % 3600 / 60
  start_secs = start_time - (start_hours * 3600 + start_mins * 60)

  end_hours =  end_time / 3600
  end_mins = end_time % 3600 / 60
  end_secs = end_time - (end_hours * 3600 + end_mins * 60)

  time_format = "%02d:%02d:%02d,%03d"
  s = time_format % [start_hours, start_mins, start_secs, start_ms]
  e = time_format % [end_hours, end_mins, end_secs, end_ms]

  "#{s} --> #{e}\r\n"
end

# Timeshift in seconds
shift = ARGV[1].to_i

@output = ""

File.open(ARGV[0], 'r').each do |line|
  parts = line.split(":")
  if parts.length == 5
    @output << change_sub_time(parts, shift)
  else
    @output << line
  end
end

puts @output
