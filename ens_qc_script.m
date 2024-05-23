addpath('~/MatlabToolboxes/fieldtrip/')
ft_defaults
addpath('~/git/usr/matlab/qc-ensemble-eeg/')
addpath('~/MyScripts/')
addpath('~/git/usr/matlab/similar-ear-elephant/')

edffiles = dir('./**/*.edf');
subj = table();
for i = 1:length(edffiles)
    everythingOK = true;
    problems = {};
    warnings = {};
    
    % checking filename
    currFilename = edffiles(i).name;
    [currSubj, functionOK, problem] = ens_qc_check_filename(currFilename);
    if ~functionOK
        everythingOK = false;
    end
    problems = cat(1,problems, problem);

    % settings up filename fields
    currSubj.filename = currFilename;
    currSubj.path_to_file = edffiles(i).folder;

    % checking channels
    [currSubj, functionOK, problem, warning] = ens_qc_check_channels(currSubj);
    problems = cat(1, problems, problem);
    warnings = cat(1, warnings, warning);
    if ~functionOK
        everythingOK = false;
    end

    % quick visual check
    ens_qc_visual_check(currSubj)

    % quality control
    switch currSubj.acq
        case "ceeg"
            [currSubj, functionOK, problem, warning] = ens_qc_check_ceeg(currSubj);
        case "aeeg"
            [currSubj, functionOK, problem, warning] = ens_qc_check_aeeg(currSubj);

        otherwise
            currSubj.everythingOK = false;
            problem = sprintf( ...
                "Unknown acquisition field entry (%s), cannot run analysis", ...
                currSubj(i).acq);
            problems = cat(1, problems, problem);
    end

    % create figures
    ens_qc_figures(currSubj)

    currSubj.everythingOK = everythingOK;
    currSubj.problems = problems;
    currSubj.warnings = warnings;
    subj(i,:) = struct2table(currSubj, 'AsArray', true);

end

