function currSubj = ens_qc_prepare_subject(bidsFilename)

fields = strsplit(bidsFilename,'_');

for i = 1:length(fields)
    splitField = strsplit(fields{i},'-');

    if length(splitField)==2
        currSubj.(splitField{1}) = splitField{2};
    end
end


