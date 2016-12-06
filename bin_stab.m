function bin = bin_stab(utility_before, utility_after, members_coalition_leave, members_coalition_join, deviator)

bin_Nash = false;
bin_Individual = false;
bin_Contractual = false;

% the coalition which the deviator leaves 
PO_leave = true;
if any(members_coalition_leave)
PO_leave = (utility_after(members_coalition_leave) >= utility_before(members_coalition_leave));
end

% the coalition which the deviator joins 
PO_join = true;
if any(members_coalition_join)
PO_join = (utility_after(members_coalition_join) >= utility_before(members_coalition_join));
end

% if the deviator improves his utility
if utility_after(deviator) > utility_before(deviator)
    bin_Nash = true;
end

if bin_Nash && all(PO_join)
    bin_Individual = true;
end

if bin_Individual && all(PO_leave)
    bin_Contractual = true;
end

bin = [bin_Nash, bin_Individual, bin_Contractual];