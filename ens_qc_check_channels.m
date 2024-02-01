function [currSubj, everythingOK, problems, warnings] = ens_qc_check_channels(currSubj)

% set starting values
warnings = '';
problems = '';
everythingOK = true;

% Normal EEG labels 
cfg = [];
cfg.layout = 'biosemi64';
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
lay = ft_prepare_layout(cfg);

filename = [currSubj.path_to_file filesep currSubj.filename];
hdr = ft_read_header(filename);

% check channels
if all(contains(hdr.label(contains(hdr.label, lay.label)), '-'))
    currSubj.montage = 'bipolar';
else
    currSubj.montage = 'referential';
end

temp_channels = hdr.label;
if any(not(cellfun(@isempty, regexp(hdr.label, '^EEG '))))
    temp_channels = cellfun(@(x) x(5:end), temp_channels, 'un',0);
end

if any(ismember({'T3', 'T4', 'T5', 'T6'}, temp_channels))
    % rename outdated labels
    temp_channels(ismember(temp_channels, 'T3')) = {'T7'};
    temp_channels(ismember(temp_channels, 'T4')) = {'T8'};
    temp_channels(ismember(temp_channels, 'T5')) = {'P7'};
    temp_channels(ismember(temp_channels, 'T6')) = {'P8'};

    warnings = 'Outdated channel labels detected, consider renaming channels';
end

switch currSubj.montage
    case 'bipolar'
        % calculate types of channels
        temp_channels = cellfun(@(y) strsplit(y, '-'), temp_channels, 'un',0);
        currSubj.eeg_channels = hdr.label(cellfun(@(x) any(ismember(x, lay.label)), temp_channels)&~contains(hdr.label, 'EOG'));
        currSubj.eog_channels = hdr.label(contains(hdr.label, 'EOG'));
        currSubj.reference_channels = {};
        currSubj.non_eeg_channels = hdr.label(~ismember(hdr.label, [currSubj.eeg_channels; currSubj.eog_channels]));

        % calculate number of electrode points for eeg channels
        temp_channels = unique(cat(2, temp_channels{:}));
        electrode_locations = temp_channels(ismember(temp_channels, lay.label));
        currSubj.n_electrodes = length(electrode_locations);

    case 'referential'
        currSubj.eeg_channels = hdr.label(ismember(temp_channels, lay.label));
        currSubj.eog_channels = hdr.label(contains(hdr.label, 'EOG'));
        currSubj.reference_channels = hdr.label( ...
            ismember(temp_channels, {'A1','A2', 'M1', 'M2'}));
        currSubj.non_eeg_channels = hdr.label( ...
            ~ismember(hdr.label, [currSubj.eeg_channels; ...
            currSubj.eog_channels; currSubj.reference_channels]));
        currSubj.n_electrodes = length(currSubj.eeg_channels);
        
    otherwise
end

switch currSubj.acq
    case 'aeeg'
        if currSubj.n_electrodes < 2
            everythingOK = false;
            problem = sprintf('too few eeg channels detected (%1.0f)', currSubj.n_electrodes);
        end
    case 'ceeg'
        if currSubj.n_electrodes < 9
            everythingOK = false;
            problem = sprintf('too few eeg channels detected (%1.0f)', currSubj.n_electrodes);
        end
end


