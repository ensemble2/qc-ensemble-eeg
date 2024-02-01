function ens_qc_visual_check(currSubj)

filename = [currSubj.path_to_file filesep currSubj.filename];

figure_folder = './FIGURES';
if ~exist(figure_folder, 'dir')
    mkdir(figure_folder)
end

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
figure1_path = [figure_folder filesep currSubj.sub '_rawdata.png'];
export_fig(figure1_path, '-r300')

pause;
close all

[~, fd] = bvLL_frequencyanalysis(data, [0 50], 'fourier', true);
figure; semilogy(fd.freq, squeeze(nanmedian(fd.powspctrm,1)))
figure1_path = [figure_folder filesep currSubj.sub '_freqdata.png'];
export_fig(figure1_path, '-r300')

pause;
close all