function bin = bin_PO(values_before, values_temp)

bin = false;

if all(values_temp >= values_before) && any(values_temp > values_before)
    bin = true;
end

end