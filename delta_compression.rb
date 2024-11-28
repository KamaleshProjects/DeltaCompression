
##
# returns the delta series of the time series integer data passed in
# the first element of the time series data is taken as is in the delta array
# subsequent elements are delta = time_series_data[i] - time_series_data[i-1]
# the time series array passed in is unmutated, the delta is returned in a new array
def to_delta(time_series_int_arr)
  arr_len = time_series_int_arr.length
  if arr_len < 1
    raise "Error: time_series_int_arr should contain atleast one element, length: ${arr_len}"
  end

  time_series_delta_arr = Array.new(arr_len)
  time_series_delta_arr[0] = time_series_int_arr[0]

  (1...arr_len).each do |i|
    time_series_delta_arr[i] = time_series_int_arr[i] - time_series_int_arr[i-1]
  end

  return time_series_delta_arr
end

##
# returns the original time series data from which the time series delta was constructed from
# the first element of the time delta is taken as is in the time series array
# subsequent elements are time_series_data[i] = time_series_delta_arr[i] + time_series_data[i-1]
# the delta array is unmutated, the time series data is returned in a new array
def to_time_series(time_series_delta_arr)
  arr_len = time_series_delta_arr.length
  if arr_len < 1
    raise "Error: time_series_delta_arr should contain atleast one element, length: ${arr_len}"
  end

  time_series_int_arr = Array.new(arr_len)
  time_series_int_arr[0] = time_series_delta_arr[0]

  (1...arr_len).each do |i|
    time_series_int_arr[i] = time_series_delta_arr[i] + time_series_int_arr[i-1]
  end

  return time_series_int_arr
end

##
# returns variable length integer encoded as a byte array
# ex: b'100100100
# b'00000010 <- b'10100100
# if msb is set it indicates continuation
# arr = [b'10100100, b'00000010]
# read the array forward but the bits backward
def encode_var_len_int(value) 
  bytes = []

  negative = value < 0

  # Zig Zag encoding 
  # -3 => 101 => 3 => 011 => 110 => 111
  # 3 => 011 => 3 => 011 => 110 => 110
  value = (value.abs << 1) | (negative ? 1 : 0)

  while value >= 0x80 # while value greater than b'10000000 (cannot fit inside 7 bits)
    
    # 0x7f is basically b'01111111 anding any num with 0x7f is going to get you the lowest 7 bits
    # ex: b'1111101000 & b'01111111 => b'0001001000
    lower_7_bits = value & 0x7f

    # mark continuation bit 0x80 is b'10000000 (8th bit) and append to bytes array
    bytes << (lower_7_bits | 0x80)

    # right shift value by 7 bits to move on with next iteration of encoding of 7 bits
    value >>= 7
  end

  # append last byte without msb set
  bytes << value

  return bytes
end

## Tests
# to_delta

# init time series data with low variance
center = 10000
variance = 5
size = 100

time_series_int_arr = Array.new(size) do 
  center + rand(-variance..variance)
end

# delta conversion
time_series_delta_arr = to_delta(time_series_int_arr)

# time series conversion
recon_time_series_int_arr = to_time_series(time_series_delta_arr) 

puts "time series data: #{time_series_int_arr.inspect}"
puts
puts "time series delta: #{time_series_delta_arr.inspect}"
puts
puts "reconstructed time series data: #{recon_time_series_int_arr.inspect}"

# time series data
puts "Writing time series data to file..."

File.open("time_series.bin", "wb") do |file| 
  file.write(time_series_int_arr.pack("l*")) # "l*" packs integers as 32-bit signed integers
end 

# time series delta
puts "Writing time series delta to file..."

File.open("delta.bin", "wb") do |file|
  file.write(time_series_delta_arr.pack("l*")) 
end

# time series variable length encoded integers
puts "Writing variable length encoded integers to file"

File.open("varint.bin", "wb") do |file|
  time_series_int_arr.each do |val|
    file.write(encode_var_len_int(val).pack("C*")) # Pack bytes as unsigned chars
  end
end

# time series variable length encoded and delta compressed integers
puts "Writing variable length encoded delta series to file"

File.open("varint_delta.bin", "wb") do |file|
  time_series_delta_arr.each do |val|
    file.write(encode_var_len_int(val).pack("C*")) # Pack bytes as unsigned chars
  end
end

puts "Writes complete"

