function [currSubj, everythingOK, problems, warnings] = ens_qc_check_ceeg(currSubj)

% set starting variables
everythingOK = true;
problems = {};
warnings = {};

filename = [currSubj.path_to_file filesep currSubj.filename];

% check header
hdr = ft_read_header(filename);
currSubj.sampling_frequency = hdr.Fs;
if currSubj.sampling_frequency < 256
    everythingOK = false;
    problem{1} = sprintf('Too low sampling frequency (%1.0f) for acquisition type (ceeg)', currSubj.sampling_frequency);
    problems = cat(1, problems, problem);
end

currSubj.recording_length_in_mins = hdr.nSamples./hdr.Fs./60;
if currSubj.recording_length_in_mins < 60
    everythingOK = false;
    problem{1} = sprintf('Too low recording length (%1.0f mins) for acquisition type (ceeg)', currSubj.recording_length_in_mins);
    problems = cat(1, problems, problem);
end

% read in data
cfg = [];
cfg.headerfile = filename;
cfg.dataset = filename;
cfg.hpfilter = 'yes';
cfg.hpfreq = 0.16;
cfg.hpinstabilityfix = 'reduce';
cfg.channel = currSubj.eeg_channels;
data = ft_preprocessing(cfg);

% cut in trials
cfg = [];
cfg.length = 1;
cfg.overlap = 0;
dataCut = ft_redefinetrial(cfg, data);

for i = 1:length(dataCut.trial)
    kurt(i,:) = kurtosis(dataCut.trial{i}, [], 2);
    var(i,:) = std(dataCut.trial{i},[],2).^2;
    maxval(i,:) = max(abs(dataCut.trial{i}),[],2);
end

% jump
cfg = [];
cfg.artfctdef.jump.channel = dataCut.label;
cfg.artfctdef.jump.interactive = 'no';
cfg.continuous = 'no';
[~,artifact] = ft_artifact_jump(cfg, dataCut);

for i = 1:size(artifact,1)
    [~,sel(i)] = min(abs(mean(dataCut.sampleinfo,2) - mean(artifact(i,:))));
end

% flatline
updateWaitbar = waitbarParfor(...
    length(dataCut.trial)*size(dataCut.trial{1}, 1), ...
    'Detecting flatlines');
for j = 1:length(dataCut.trial)
    a = double(abs(diff(diff(dataCut.trial{j},[],2),[],2))<0.000001);
    for i = 1:size(a, 1)
        G = a(i,:);
        ix = cumsum([true diff(G,[],2)~=0]);                              % index the sections
        tmp = arrayfun(@(k) cumsum(G(ix==k)), 1:ix(end), 'un', 0);    % cumsum each section
        H = cat(2,tmp{:});       % concatenate the cells
        nflat(i,j) = max(H);
        updateWaitbar()
    end
end

badFlat = find(any((nflat>20)));
badJump = sel;
badKurt = find(any(kurt > 7, 2));
badVar = find(any(var > 1500, 2));
badMax = find(any(maxval > 200,2));

currSubj.n_bad_trials = length(unique( [badFlat, badJump, badKurt', badVar', badMax'] ));
currSubj.perc_bad_data = round(currSubj.n_bad_trials ./ length(dataCut.trial) .* 100,1);
currSubj.clean_data_in_s = length(dataCut.trial) - currSubj.n_bad_trials;

if currSubj.perc_bad_data > 50
    problem{1} = sprintf('Data too noisy (%1.1f%% noise)', currSubj.perc_bad_data);
    problems = cat(1, problems, problem);
end
