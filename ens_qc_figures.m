function ens_qc_figures(currSubj)

filename = [currSubj.path_to_file filesep currSubj.filename];

% read in data
cfg = [];
cfg.headerfile = filename;
cfg.dataset = filename;
cfg.hpfilter = 'yes';
cfg.hpfreq = 0.16;
cfg.hpinstabilityfix = 'reduce';
cfg.bsfilter = 'yes';
cfg.bsfreq = [48 52; 98 102];
cfg.channel = currSubj.eeg_channels;
data = ft_preprocessing(cfg);

cfg = [];
cfg.viewmode = 'vertical';
cfg.ylim = [-100 100];
cfg.blocksize = 10;
ft_databrowser(cfg, data);

