#!/usr/bin/env ruby

require "faker"

DELIM="\t"

File.open("db.dat", "w") do |f|
  for i in 1..30 do
    f.write(i.to_s + DELIM)
    f.write(Faker::Name.first_name + DELIM)
    f.write(Faker::Name.last_name + DELIM)
    f.write(Faker::PhoneNumber.phone_number + DELIM)
    f.write((i % 3 == 0 ? "1" : "0") + DELIM)
    f.write(Faker::Date.backward(365).to_s + DELIM)
    f.write("\n")
  end
end
