function [subj, everythingOK, problems] = ens_qc_check_filename(filename)

everythingOK = true;
problems = {};

subj = ens_qc_prepare_subject(filename);
fnames = fieldnames(subj);
bidsFieldnames = {'sub', 'ses', 'acq', 'run'};
fieldsPresent = ismember(bidsFieldnames, fnames);

if ~all(fieldsPresent)
    everythingOK = false;
    missingFields = bidsFieldnames(fieldsPresent==0);
    problem{1} = sprintf(['Filename not according to BIDS standard: ', ...
        repmat('%s ', 1,  length(missingFields)), ...
        'missing'], bidsFieldnames{fieldsPresent==0});
    problems = cat(1, problems, problem);
    for i = 1:length(missingFields)
        subj.(missingFields{i}) = '';
    end
end

if isfield(subj, 'sub')
    correctPseudonym = check_pseudonym(subj.sub);
    if ~correctPseudonym
        everythingOK = false;
        problem{1} = sprintf( ...
            'Pseudonym (%s) is not according to ENSEMBLE standards', ...
            subj.sub);
        problems = cat(1, problems, problem);
    end
end

function everythingOK = check_pseudonym(pseudonym)
everythingOK = ~isempty(regexp(pseudonym, '\d{3}E\d{6}', 'once'));

